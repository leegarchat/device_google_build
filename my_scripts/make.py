#!/usr/bin/env python3
"""
make.py - Изолированный движок компиляции Android ROM и модулей.
Входит в состав инструментария сборщика.
"""

import os
import sys
import re
import json
import shutil
import signal
import argparse
import subprocess
import threading
from pathlib import Path
from datetime import datetime

# ============================================================
# 1. Безопасность и экстренное завершение (SIGINT / SIGTERM)
# ============================================================
ACTIVE_BUILD_PROCESS: subprocess.Popen | None = None
res_lock = threading.Lock()

def emergency_cleanup(signum, frame):
    """Останавливает запущенный процесс Ninja/Soong при прерывании."""
    global ACTIVE_BUILD_PROCESS
    with res_lock:
        if ACTIVE_BUILD_PROCESS and ACTIVE_BUILD_PROCESS.poll() is None:
            try:
                ACTIVE_BUILD_PROCESS.terminate()
                ACTIVE_BUILD_PROCESS.wait(timeout=2.0)
            except Exception:
                try:
                    ACTIVE_BUILD_PROCESS.kill()
                except Exception:
                    pass
    console.print("\n[bold red]⚠️ Сборка прервана пользователем (SIGINT)[/bold red]")
    os._exit(130)

signal.signal(signal.SIGINT, emergency_cleanup)
signal.signal(signal.SIGTERM, emergency_cleanup)

# ============================================================
# 2. Проверка и самовосстановление зависимостей (Self-Healing)
# ============================================================
def ensure_rich():
    """Проверяет наличие библиотеки rich и устанавливает её при отсутствии."""
    try:
        import rich
    except ImportError:
        print("[*] Установка интерфейсной библиотеки 'rich'...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "rich", "--quiet"])

ensure_rich()

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeRemainingColumn
from rich.panel import Panel
from rich.live import Live
from rich.layout import Layout
from rich.text import Text
from rich.table import Table

console = Console()

# ============================================================
# 3. Вспомогательные функции прав и путей
# ============================================================
DEFAULT_KERNEL_BASE = Path("device/google/pixel-kernels")
DEFAULT_RELEASE_BASE = Path("device/google/release")

def get_target_uid_gid() -> tuple[int, int]:
    """Извлекает UID и GID непривилегированного пользователя."""
    sudo_uid = os.environ.get("SUDO_UID")
    sudo_gid = os.environ.get("SUDO_GID")
    if sudo_uid and sudo_gid:
        return int(sudo_uid), int(sudo_gid)
    return os.getuid(), os.getgid()

def fix_permissions(path: Path, uid: int, gid: int):
    """Сбрасывает владельца и права доступа к файлу/каталогу."""
    if uid == 0 or not path.exists():
        return
    try:
        subprocess.run(["chown", "-R", f"{uid}:{gid}", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["chmod", "-R", "u+rwX,go+rX", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

# ============================================================
# 4. Просмотр доступных ядер (--ls-kernel / -s) с валидацией
# ============================================================
def inspect_kernel_dir(kernel_dir: Path) -> dict | None:
    """Проверяет каталог на наличие полного комплекта артефактов ядра."""
    if not kernel_dir.is_dir() or kernel_dir.name.startswith(".") or kernel_dir.name == "anykernels":
        return None

    all_files = [f for f in kernel_dir.rglob("*") if f.is_file()]
    file_names = {f.name for f in all_files}
    suffixes = {f.suffix for f in all_files}

    has_ko = any(s == ".ko" for s in suffixes)
    has_boot = "boot.img" in file_names
    has_dtb = "dtb.img" in file_names or any(f.name.endswith(".dtb") or f.name == "dtb" for f in all_files)
    has_dtbo = "dtbo.img" in file_names
    has_image = any(f.name in ("Image", "Image.gz", "Image.lz4") for f in all_files)
    has_load_blocklist = any(s in (".load", ".blocklist") for s in suffixes)

    # Строгая проверка: считаем ядро валидным ТОЛЬКО при наличии ВСЕХ необходимых компонентов
    is_valid = has_ko and has_boot and has_dtb and has_dtbo and has_image and has_load_blocklist
    if not is_valid:
        return None

    has_vendor_boot = "vendor_boot.img" in file_names

    return {
        "name": kernel_dir.name,
        "has_vendor_boot": has_vendor_boot
    }

def list_kernels(target_path: Path):
    """Выводит таблицу полностью готовых каталогов ядер с указанием наличия vendor_boot.img."""
    console.print(Panel(f"[bold cyan]📦 Проверка и список доступных ядер в:[/] [white]{target_path.resolve()}[/white]", expand=False))

    if not target_path.exists() or not target_path.is_dir():
        console.print(f"[bold red]❌ Ошибка: Указанная директория '{target_path}' не существует![/bold red]")
        return

    valid_kernels = []
    for item in sorted(target_path.iterdir(), key=lambda x: x.name):
        info = inspect_kernel_dir(item)
        if info:
            valid_kernels.append(info)

    if not valid_kernels:
        console.print("[yellow]В указанном каталоге готовые валидные директории ядер не найдены.[/yellow]")
        return

    table = Table(show_header=True, header_style="bold magenta", expand=True)
    table.add_column("№", style="cyan", width=5)
    table.add_column("Имя директории ядра", style="bold white")
    table.add_column("vendor_boot.img", style="bold", justify="center", width=18)

    for idx, k in enumerate(valid_kernels, 1):
        vboot_status = "[green]✓ Есть[/green]" if k["has_vendor_boot"] else "[dim]-[/dim]"
        table.add_row(str(idx), k["name"], vboot_status)

    console.print(table)

# ============================================================
# 5. Захват и сохранение окружения (Bash Subshell Env Parser)
# ============================================================
def setup_build_environment(device: str, build_type: str, version: str, force_env: bool, force_lunch: bool) -> dict[str, str]:
    """
    Выполняет source build/envsetup.sh и lunch во внутреннем bash-контексте с живым выводом.
    Сохраняет полный вывод в out/build_logs/envsetup.log и извлекает итоговый словарь переменных окружения.
    """
    log_dir = Path("out/build_logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    env_log_path = log_dir / "envsetup.log"

    lunch_targets = [
        f"lineage_{device}-{version}-{build_type}",
        f"evolution_{device}-{version}-{build_type}",
        f"evolution_{device}-{build_type}",
        f"lineage_{device}-{build_type}",
        f"aosp_{device}-{build_type}",
    ]

    lunch_chain = " || ".join([f"lunch {target}" for target in lunch_targets])
    primary_lunch = lunch_targets[0]

    console.print(f"[yellow]--> Подготовка окружения сборщика ({primary_lunch})...[/yellow]")

    delimiter = "===END_OF_LUNCH_ENV_CAPTURE==="
    bash_cmd = (
        f"source build/envsetup.sh && "
        f"({lunch_chain}) && "
        f"echo '{delimiter}' && "
        f"env"
    )

    current_env = os.environ.copy()
    current_env["PYTHONUNBUFFERED"] = "1"

    process = subprocess.Popen(
        ["bash", "-c", bash_cmd],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True,
        env=current_env
    )

    env_output_lines = []
    is_capturing_env = False

    try:
        with open(env_log_path, "w", encoding="utf-8", errors="replace") as f:
            f.write(f"=== ENVSETUP & LUNCH LOG ({datetime.now()}) ===\n")
            
            line_buffer = []
            while True:
                char = process.stdout.read(1)
                if not char:
                    if line_buffer:
                        line = "".join(line_buffer)
                        f.write(line + "\n")
                    break

                if char in ("\r", "\n"):
                    clean_line = "".join(line_buffer).strip()
                    if char == "\n":
                        f.write("".join(line_buffer) + "\n")
                        f.flush()
                    line_buffer = []

                    if clean_line == delimiter:
                        is_capturing_env = True
                        continue

                    if is_capturing_env:
                        if clean_line:
                            env_output_lines.append(clean_line)
                    else:
                        if clean_line:
                            console.print(f"  [dim white]>[/dim white] [dim]{clean_line[:120]}[/dim]")
                else:
                    line_buffer.append(char)

            process.wait()

        if process.returncode != 0 or not is_capturing_env:
            console.print(f"[bold red]❌ Сбой инициализации lunch/envsetup![/bold red]")
            console.print(Panel(f"Детали ошибки сохранены в [yellow]{env_log_path}[/yellow]", border_style="red"))
            sys.exit(1)

        new_env = {}
        for line in env_output_lines:
            if "=" in line:
                k, v = line.split("=", 1)
                new_env[k] = v

        os.environ.update(new_env)
        console.print(f"[bold green]✓ Окружение успешно настроено. Лог:[/] {env_log_path}")
        return new_env

    except Exception as e:
        console.print(f"[bold red]❌ Сбой процесса сбора окружения:[/] {e}")
        sys.exit(1)

# ============================================================
# 6. Движок выполнения компиляции и вывода логов
# ============================================================
def execute_build(
    target_cmd: str, 
    jobs: int, 
    device: str, 
    env: dict[str, str], 
    uid: int, 
    gid: int
) -> bool:
    """Запускает процесс сборки и отображает динамический прогресс в реальном времени."""
    global ACTIVE_BUILD_PROCESS

    log_dir = Path("out/build_logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    fix_permissions(log_dir, uid, gid)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_path = log_dir / f"build_{device}_{timestamp}.log"

    console.print(Panel(
        f"[bold green]Запуск сборки:[/] [white]{target_cmd}[/white] [cyan](-j{jobs})[/cyan]\n"
        f"[dim]Файл полного лога:[/] [yellow]{log_file_path}[/yellow]",
        expand=False
    ))

    ninja_progress_regex = re.compile(r"\[\s*(\d+)%\s+(\d+)/(\d+)\]\s*(.*)")
    
    # Инициализируем функцию 'm' во внутреннем bash-контексте с сохранением переменных окружения
    cmd = ["bash", "-c", f"source build/envsetup.sh > /dev/null 2>&1 && m {target_cmd} -j{jobs}"]

    build_env = env.copy()
    build_env["PYTHONUNBUFFERED"] = "1"

    try:
        with open(log_file_path, "w", encoding="utf-8", errors="replace") as log_file:
            log_file.write(f"=== BUILD STARTED: {datetime.now()} ===\n")
            log_file.write(f"Command: {' '.join(cmd)}\n\n")
            log_file.flush()

            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True,
                env=build_env
            )

            with res_lock:
                ACTIVE_BUILD_PROCESS = process

            progress = Progress(
                SpinnerColumn(),
                TextColumn("[bold cyan]{task.description}[/]"),
                BarColumn(bar_width=30),
                TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
                TextColumn("• [yellow]{task.fields[current]}/{task.fields[total_cnt]}[/]"),
                TimeRemainingColumn()
            )

            task_id = progress.add_task("Компиляция Android", total=100, current=0, total_cnt=1)
            last_status_line = "Инициализация Soong / Kati..."

            layout = Layout()
            layout.split(
                Layout(progress, name="progress", size=3),
                Layout(name="status", size=2)
            )

            with Live(layout, console=console, refresh_per_second=10):
                line_buffer = []
                while True:
                    char = process.stdout.read(1)
                    if not char:
                        if line_buffer:
                            line = "".join(line_buffer)
                            log_file.write(line + "\n")
                        break

                    if char in ("\r", "\n"):
                        clean_line = "".join(line_buffer).strip()
                        if char == "\n":
                            log_file.write("".join(line_buffer) + "\n")
                            log_file.flush()
                        line_buffer = []

                        if not clean_line:
                            continue

                        match = ninja_progress_regex.match(clean_line)
                        if match:
                            pct = int(match.group(1))
                            curr = int(match.group(2))
                            tot = int(match.group(3))
                            step_text = match.group(4)

                            progress.update(
                                task_id,
                                completed=pct,
                                current=curr,
                                total_cnt=tot,
                                total=100
                            )
                            last_status_line = step_text[:120]
                        else:
                            last_status_line = clean_line[:120]

                        status_text = Text(f" > {last_status_line}", style="dim white", overflow="ellipsis")
                        layout["status"].update(Panel(status_text, border_style="blue"))
                    else:
                        line_buffer.append(char)

            process.wait()
            success = (process.returncode == 0)

            log_file.write(f"\n=== BUILD FINISHED: {datetime.now()}, EXIT CODE: {process.returncode} ===\n")

    except Exception as e:
        console.print(f"[bold red]❌ Ошибка процесса сборки:[/] {e}")
        success = False
    finally:
        with res_lock:
            ACTIVE_BUILD_PROCESS = None
        fix_permissions(log_file_path, uid, gid)

    if success:
        console.print("\n[bold green]✨ Сборка успешно завершена![/bold green]")
    else:
        console.print(f"\n[bold red]❌ Сборка завершилась с ошибкой! См. детальный лог:[/] {log_file_path}")

    return success

# ============================================================
# 7. Релиз-менеджер и обработка JSON OTA (--release / --json)
# ============================================================
def process_ota_json(json_src: Path, json_dst: Path):
    """Считывает исходный JSON устройства и внедряет дополнительные манифест-поля."""
    try:
        with open(json_src, "r", encoding="utf-8") as f:
            data = json.load(f)

        resp = data["response"][0]

        resp["maintainer"] = "LeeGarChat"
        resp["oem"] = "Google"
        resp["buildtype"] = "user"
        resp["forum"] = "https://t.me/EvoX_LeeGarChat"
        resp["paypal"] = "https://boosty.to/leegar/"
        resp["github"] = "leegarchat"
        resp["currently_maintained"] = True

        ts = resp.get("timestamp", 0)
        try:
            dt = datetime.fromtimestamp(int(ts))
            human = dt.strftime("%Y-%m-%d %H:%M:%S")
            new_resp = {}
            for k, v in resp.items():
                new_resp[k] = v
                if k == "timestamp":
                    new_resp["_timestamp_readable"] = f"{human} (локальный часовой пояс)"
                    new_resp["_timestamp_convert_cmd"] = f"date -d '{human}' +%s"
                    new_resp["_timestamp_note"] = "Редактируйте _timestamp_readable, затем запустите _timestamp_convert_cmd"
            data["response"][0] = new_resp
        except Exception:
            pass

        with open(json_dst, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        console.print(f"  [bold green]✓ OTA JSON сохранен:[/] {json_dst.name}")
    except Exception as e:
        console.print(f"  [bold red]❌ Ошибка обработки JSON:[/] {e}")

def do_release_export(
    device: str, 
    kernel_suffix: str, 
    custom_release_path: Path | None, 
    modify_json: bool, 
    uid: int, 
    gid: int
):
    """Копирует готовые артефакты сборки в папку релиза."""
    src_dir = Path(f"out/target/product/{device}")
    date_str = datetime.now().strftime("%Y%m%d")

    if custom_release_path:
        release_dir = custom_release_path.resolve()
    else:
        release_dir = DEFAULT_RELEASE_BASE / date_str / device / (kernel_suffix or "StockKernel")

    console.print(Panel(f"[bold cyan]=== RELEASE: Сохранение артефактов в {release_dir} ===[/bold cyan]", expand=False))
    release_dir.mkdir(parents=True, exist_ok=True)

    zip_files = sorted(src_dir.glob("*.zip"), key=lambda x: x.stat().st_mtime, reverse=True)
    if not zip_files:
        console.print(f"[bold red]❌ Ошибка: Готовый ZIP-архив прошивки не найден в {src_dir}![/bold red]")
        return

    target_zip = zip_files[0]
    console.print(f"  [green]Копирование ZIP:[/] {target_zip.name}")
    shutil.copy2(target_zip, release_dir / target_zip.name)

    image_names = ["dtbo.img", "vendor_boot.img", "vendor_kernel_boot.img", "boot.img", "init_boot.img"]
    for img_name in image_names:
        img_file = src_dir / img_name
        if img_file.exists():
            console.print(f"  [green]Копирование:[/] {img_name}")
            shutil.copy2(img_file, release_dir / img_name)

    for vb_file in src_dir.glob("vbmeta*.img"):
        console.print(f"  [green]Копирование:[/] {vb_file.name}")
        shutil.copy2(vb_file, release_dir / vb_file.name)

    if modify_json:
        json_src = src_dir / f"{device}.json"
        if json_src.exists():
            json_dst = release_dir / f"{target_zip.stem}.json"
            process_ota_json(json_src, json_dst)

    fix_permissions(release_dir, uid, gid)
    console.print(f"\n[bold green]✓ Релиз успешно сформирован в:[/] {release_dir}\n")

# ============================================================
# 8. Точка входа и парсинг аргументов
# ============================================================
def main():
    parser = argparse.ArgumentParser(
        description="Android ROM & Module Build Engine (make.py)",
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument("-b", "--build", action="store_true", help="Запустить компиляцию целевого объекта")
    parser.add_argument("-a", "--app", type=str, default=None, help="Имя конкретного модуля/приложения для сборки (например, Settings)")
    parser.add_argument("-v", "--version", type=str, default="cp2a", help="Версия платформы для lunch (по умолчанию: cp2a)")
    
    parser.add_argument("-e", "--env", action="store_true", 
                        help="Принудительно перезапустить 'source build/envsetup.sh'.\n"
                             "Используется при изменениях внутренних bash-скриптов или функций сборщика.")
    
    parser.add_argument("-l", "--lunch", action="store_true", 
                        help="Принудительно перезапустить команду 'lunch'.\n"
                             "Используется для сброса конфигурации целевой платформы без перечитывания Soong.")

    parser.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 8, 
                        help="Количество параллельных потоков сборки (например: -j16 или -j 16)")

    parser.add_argument("-k", "--kernel", type=str, default="", help="Имя подкаталога ядра из device/google/pixel-kernels/")
    
    parser.add_argument("-s", "--ls-kernel", nargs="?", const="DEFAULT", default=None,
                        help="Вывести список доступных ядер с валидацией состава файлов.\n"
                             "Без параметров: проверяет device/google/pixel-kernels/\n"
                             "С параметром: проверяет переданный путь")

    parser.add_argument("-t", "--type", type=str, default="userdebug", choices=["user", "userdebug", "eng"], 
                        help="Тип сборки (user, userdebug, eng)")
    
    parser.add_argument("-d", "--device", type=str, default="", help="Кодовое имя целевого устройства (например: shiba, husky)")

    parser.add_argument("-r", "--release", nargs="?", const="DEFAULT", default=None,
                        help="Сохранить релизные артефакты.\n"
                             "Без параметров: сохраняет в device/google/release/YYYYMMDD/DEVICE/KERNEL/\n"
                             "С параметром: сохраняет по указанному пути")

    parser.add_argument("-J", "--json", action="store_true", help="Модифицировать и сохранить OTA JSON манифест при экспорте релиза")

    args = parser.parse_args()

    uid, gid = get_target_uid_gid()

    # 1. Просмотр доступных ядер (--ls-kernel / -s) с валидацией
    if args.ls_kernel is not None:
        target_path = DEFAULT_KERNEL_BASE if args.ls_kernel == "DEFAULT" else Path(args.ls_kernel)
        list_kernels(target_path)
        sys.exit(0)

    # 2. Проверка запускных флагов
    if not args.build:
        console.print("[yellow]Предупреждение: Флаг --build не передан. Запустите с --help для просмотра справки.[/yellow]")
        sys.exit(0)

    if not args.device:
        console.print("[bold red]❌ Ошибка: Для запуска сборки необходимо указать устройство (--device / -d)![/bold red]")
        sys.exit(1)

    # 3. Установка переменной ядра
    if args.kernel:
        os.environ["TARGET_KERNEL_DIR_EXT"] = args.kernel
        console.print(f"[bold green]✓ Установлено кастомное ядро:[/] {args.kernel}")

    # 4. Настройка окружения (Envsetup & Lunch)
    build_env = setup_build_environment(
        device=args.device,
        build_type=args.type,
        version=args.version,
        force_env=args.env,
        force_lunch=args.lunch
    )

    # 5. Выбор целевой команды
    target_cmd = args.app if args.app else "evolution"

    # 6. Запуск процесса компиляции
    success = execute_build(
        target_cmd=target_cmd,
        jobs=args.jobs,
        device=args.device,
        env=build_env,
        uid=uid,
        gid=gid
    )

    # 7. Экспорт релиза
    if success and args.release is not None:
        custom_path = None if args.release == "DEFAULT" else Path(args.release)
        do_release_export(
            device=args.device,
            kernel_suffix=args.kernel,
            custom_release_path=custom_path,
            modify_json=args.json,
            uid=uid,
            gid=gid
        )

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()