#!/usr/bin/env python3
"""
kill_soong.py - Безопасная остановка процессов сборки Android (Soong/Ninja) и очистка lock-файлов.

КРИТИЧЕСКАЯ ОСОБЕННОСТЬ:
Удаляет только блокирующие runtime-файлы (.lock), не затрагивая кэши Soong, Kati и Ninja 
(.ninja_deps, .ninja_log, .kati_stamp, build.ninja).
Это предотвращает повторный долгий прогон анализа всех Android.bp файлов при следующем запуске.
"""

import os
import sys
import time
import signal
import argparse
import subprocess
import threading
from pathlib import Path

# ============================================================
# 1. Безопасность и аварийное завершение (SIGINT / SIGTERM)
# ============================================================
res_lock = threading.Lock()

def emergency_cleanup(signum, frame):
    os._exit(130)

signal.signal(signal.SIGINT, emergency_cleanup)
signal.signal(signal.SIGTERM, emergency_cleanup)

# ============================================================
# 2. Проверка и самовосстановление зависимостей (Rich & Psutil)
# ============================================================
def ensure_dependencies():
    missing = []
    try:
        import rich
    except ImportError:
        missing.append("rich")
    try:
        import psutil
    except ImportError:
        missing.append("psutil")

    if missing:
        print(f"[*] Установка недостающих зависимостей: {', '.join(missing)}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install"] + missing + ["--quiet"])

ensure_dependencies()

import psutil
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.panel import Panel
from rich.table import Table

console = Console()

# ============================================================
# 3. Управление правами
# ============================================================
def get_target_uid_gid() -> tuple[int, int]:
    """Извлекает UID и GID обычного пользователя, вызвавшего sudo."""
    sudo_uid = os.environ.get("SUDO_UID")
    sudo_gid = os.environ.get("SUDO_GID")
    if sudo_uid and sudo_gid:
        return int(sudo_uid), int(sudo_gid)
    return os.getuid(), os.getgid()

def fix_permissions(path: Path, uid: int, gid: int):
    """Сбрасывает права доступа к пути."""
    if uid == 0 or not path.exists():
        return
    try:
        subprocess.run(["chown", "-R", f"{uid}:{gid}", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["chmod", "-R", "u+rwX,go+rX", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

# ============================================================
# 4. Целевые процессы и файлы блокировок
# ============================================================
TARGET_PROCESS_NAMES = {
    "soong_build", "ninja", "ckati", "make", "javac", 
    "d8", "r8", "metalava", "ziptime", "signapk", 
    "aapt2", "zipalign"
}

JAVA_BUILD_KEYWORDS = {"soong", "turbine", "metalava", "gradle", "kotlin"}

# ТОЛЬКО lock-файлы runtime блокировок! Никаких кэшей soong/kati!
SAFE_LOCK_PATTERNS = [
    "out/.lock",
    "out/soong/.lock",
    "out/soong/build.ninja.lock",
    "out/soong/.bootstrap/build.ninja.lock",
    "out/.module_paths/*.lock"
]

def is_target_process(proc: psutil.Process) -> tuple[bool, str]:
    """Определяет, относится ли процесс к системе сборки Android."""
    try:
        pid = proc.pid
        if pid == os.getpid() or pid == os.getppid():
            return False, ""

        name = proc.name().lower()
        
        # 1. Прямое совпадение имени бинарника
        if name in TARGET_PROCESS_NAMES:
            return True, name

        # 2. Проверка Java процессов сборки
        if name in ("java", "java.exe"):
            cmdline = " ".join(proc.cmdline()).lower()
            for kw in JAVA_BUILD_KEYWORDS:
                if kw in cmdline:
                    return True, f"java ({kw})"

        return False, ""
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
        return False, ""

# ============================================================
# 5. Логика завершения процессов и очистки lock-файлов
# ============================================================
def kill_build_processes(progress: Progress, task_id, force_kill: bool = False, dry_run: bool = False) -> list[tuple[int, str]]:
    """Находит и завершает процессы сборки."""
    progress.update(task_id, step="[yellow]Поиск процессов сборки...[/]", completed=10)
    
    target_procs: list[tuple[psutil.Process, str]] = []
    
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            is_target, reason = is_target_process(proc)
            if is_target:
                target_procs.append((proc, reason))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    if not target_procs:
        progress.update(task_id, step="[bold green]✓ Активные процессы сборки не найдены[/]", completed=50)
        return []

    killed_summary = []

    if dry_run:
        progress.update(task_id, step=f"[cyan][DRY-RUN] Найдено процессов: {len(target_procs)}[/]", completed=50)
        for proc, reason in target_procs:
            killed_summary.append((proc.pid, f"{reason} (DRY-RUN)"))
        return killed_summary

    # Шаг 1: Посылаем SIGTERM (если не затребован принудительный SIGKILL)
    if not force_kill:
        progress.update(task_id, step=f"[yellow]Остановка процессов ({len(target_procs)} шт., SIGTERM)...[/]", completed=25)
        for proc, _ in target_procs:
            try:
                proc.terminate()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Ждем 1 секунду завершения
        gone, alive = psutil.wait_procs([p for p, _ in target_procs], timeout=1.0)
    else:
        alive = [p for p, _ in target_procs]

    # Шаг 2: Принудительный SIGKILL для оставшихся
    if alive:
        progress.update(task_id, step=f"[red]Принудительное завершение ({len(alive)} шт., SIGKILL)...[/]", completed=40)
        for proc in alive:
            try:
                proc.kill()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        psutil.wait_procs(alive, timeout=1.0)

    for proc, reason in target_procs:
        killed_summary.append((proc.pid, reason))

    progress.update(task_id, step=f"[bold green]✓ Завершено процессов: {len(killed_summary)}[/]", completed=50)
    return killed_summary

def remove_lock_files(out_dir: Path, progress: Progress, task_id, dry_run: bool = False) -> list[Path]:
    """Безопасно удаляет исключительно runtime lock-файлы."""
    progress.update(task_id, step="[yellow]Поиск блокирующих lock-файлов...[/]", completed=60)
    
    removed_locks: list[Path] = []

    if not out_dir.exists():
        progress.update(task_id, step="[bold green]✓ Папка out/ отсутствует, lock-файлы не найдены[/]", completed=100)
        return []

    for pattern in SAFE_LOCK_PATTERNS:
        # Резолвим относительные паттерны от корня проекта
        if pattern.startswith("out/"):
            rel_pattern = pattern[4:]
            search_path = out_dir
        else:
            search_path = out_dir
            rel_pattern = pattern

        for lock_file in search_path.glob(rel_pattern):
            if lock_file.is_file() or lock_file.is_fifo():
                removed_locks.append(lock_file)
                if not dry_run:
                    try:
                        lock_file.unlink(missing_ok=True)
                    except Exception as e:
                        console.print(f"[bold red]Не удалось удалить {lock_file}: {e}[/]")

    progress.update(task_id, step=f"[bold green]✓ Удалено lock-файлов: {len(removed_locks)}[/]", completed=100)
    return removed_locks

# ============================================================
# 6. Главная функция и точка входа
# ============================================================
def main():
    parser = argparse.ArgumentParser(description="Android Soong/Ninja Build Killer & Lock Cleaner")
    parser.add_argument("-o", "--out-dir", type=Path, default=Path("./out"), help="Путь к каталогу out (по умолчанию: ./out)")
    parser.add_argument("-f", "--force", action="store_true", 
                        help="Сразу принудительно завершать через SIGKILL (kill -9)")
    parser.add_argument("--dry-run", action="store_true", help="Показать, что будет завершено/удалено, без реальных действий")
    args = parser.parse_args()

    uid, gid = get_target_uid_gid()
    out_dir = args.out_dir.resolve()
    print(out_dir)
    console.print(Panel("[bold red]Остановка процессов сборки Android и очистка lock-файлов[/bold red]\n"
                        "[dim]Кэш Soong/Kati/Ninja сохраняется для быстрой повторной сборки.[/dim]", expand=False))

    PROGRESS_COLUMNS = [
        SpinnerColumn(),
        TextColumn("{task.description}"),
        BarColumn(bar_width=30),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TextColumn("• {task.fields[step]}"),
    ]

    killed_procs = []
    removed_locks = []

    with Progress(*PROGRESS_COLUMNS, console=console) as progress:
        kill_task = progress.add_task("[cyan]Очистка сборщика [/]", total=100, step="Инициализация")
        
        # 1. Завершение процессов
        killed_procs = kill_build_processes(progress, kill_task, force_kill=args.force, dry_run=args.dry_run)
        
        # 2. Очистка lock-файлов
        removed_locks = remove_lock_files(out_dir, progress, kill_task, dry_run=args.dry_run)

    # Вывод результатов в виде таблицы
    if killed_procs or removed_locks:
        table = Table(title="Итоги очистки", show_header=True, header_style="bold magenta")
        table.add_column("Категория", style="cyan")
        table.add_column("Детали", style="green")

        for pid, reason in killed_procs:
            table.add_row("Процесс", f"PID: {pid} ({reason})")

        for lock in removed_locks:
            table.add_row("Lock-файл", str(lock))

        console.print("\n", table)
    else:
        console.print("\n[bold green]✓ Системное окружение сборки чистое. Действий не потребовалось.[/bold green]")

    # Восстановление прав
    if out_dir.exists():
        fix_permissions(out_dir, uid, gid)

if __name__ == "__main__":
    main()