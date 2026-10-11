#!/usr/bin/env python3
"""
setup_env.py - Автономный скрипт установки и настройки системного окружения для сборки Android ROM.
Входит в состав модульного инструментария сборщика.
"""

import os
import sys
import shutil
import signal
import argparse
import subprocess
import threading
from pathlib import Path

# ============================================================
# 1. Безопасность и экстренное завершение (SIGINT / SIGTERM)
# ============================================================
ACTIVE_MOUNTS = set()
ACTIVE_TEMP_DIRS = set()
res_lock = threading.Lock()

def emergency_cleanup(signum, frame):
    with res_lock:
        for mnt in list(ACTIVE_MOUNTS):
            subprocess.run(["umount", "-l", str(mnt)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for tmp in list(ACTIVE_TEMP_DIRS):
            shutil.rmtree(tmp, ignore_errors=True)
    os._exit(130)

signal.signal(signal.SIGINT, emergency_cleanup)
signal.signal(signal.SIGTERM, emergency_cleanup)

# ============================================================
# 2. Проверка прав и самовосстановление зависимостей (Self-Healing)
# ============================================================
def ensure_root():
    if os.geteuid() != 0:
        print("[!] Ошибка: Скрипт установки окружения требует прав root.")
        print(f"    Запустите через sudo: sudo {sys.executable} {' '.join(sys.argv)}")
        sys.exit(1)

def ensure_rich():
    try:
        import rich
    except ImportError:
        print("[*] Установка интерфейсной библиотеки 'rich'...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "rich", "--quiet"])

ensure_root()
ensure_rich()

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.panel import Panel

console = Console()

ONE_SHOT_MARKER = Path("/var/lib/android-env-setup.done")
MIN_DISK_GB = 150

# ============================================================
# 3. Вспомогательные утилиты управления правами и процессами
# ============================================================
def get_target_uid_gid() -> tuple[int, int]:
    """Извлекает UID и GID обычного пользователя, вызвавшего sudo."""
    sudo_uid = os.environ.get("SUDO_UID")
    sudo_gid = os.environ.get("SUDO_GID")
    if sudo_uid and sudo_gid:
        return int(sudo_uid), int(sudo_gid)
    return 0, 0

def fix_permissions(path: Path, uid: int, gid: int):
    """Сбрасывает владельца и восстанавливает права доступа u+rwX,go+rX."""
    if uid == 0 or not path.exists():
        return
    try:
        subprocess.run(["chown", "-R", f"{uid}:{gid}", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["chmod", "-R", "u+rwX,go+rX", str(path)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def get_os_info() -> dict[str, str]:
    """Считывает идентификаторы ОС из /etc/os-release."""
    info = {}
    os_release = Path("/etc/os-release")
    if os_release.exists():
        with open(os_release, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    info[k] = v.strip('"\'')
    return info

def run_cmd(cmd: list[str], check: bool = True, suppress: bool = True, capture: bool = False) -> subprocess.CompletedProcess:
    """Выполняет системную команду с подавлением вывода для сохранения целостности TUI."""
    stdout = subprocess.DEVNULL if suppress else (subprocess.PIPE if capture else None)
    stderr = subprocess.DEVNULL if suppress else None
    return subprocess.run(cmd, check=check, stdout=stdout, stderr=stderr)

def check_disk_space():
    """Проверяет свободное место на корне. Минимум 150 ГБ для AOSP-сборки."""
    try:
        st = os.statvfs("/")
        free_gb = (st.f_bavail * st.f_frsize) / (1024 ** 3)
        if free_gb < MIN_DISK_GB:
            console.print(f"[bold red]Мало места на диске:[/] {free_gb:.0f} ГБ свободно, нужно минимум {MIN_DISK_GB} ГБ.")
            sys.exit(1)
        console.print(f"[dim]  Свободное место: {free_gb:.0f} ГБ[/]")
    except Exception:
        pass

def is_already_setup() -> bool:
    return ONE_SHOT_MARKER.exists()

def mark_setup_done():
    ONE_SHOT_MARKER.parent.mkdir(parents=True, exist_ok=True)
    ONE_SHOT_MARKER.write_text(f"completed by setup_env.py\n", encoding="utf-8")

# ============================================================
# 4. Модули установки пакетов под дистрибутивы
# ============================================================
def setup_system_limits(progress: Progress, task_id, uid: int, gid: int):
    progress.update(task_id, step="[yellow][1/4] Настройка sysctl (inotify, память)...[/]", completed=10)

    sysctl_conf = Path("/etc/sysctl.d/99-android-build.conf")
    sysctl_content = (
        "# Android build environment limits\n"
        "fs.inotify.max_user_watches=524288\n"
        "fs.inotify.max_user_instances=1024\n"
        "vm.max_map_count=262144\n"
    )
    try:
        sysctl_conf.write_text(sysctl_content, encoding="utf-8")
        run_cmd(["sysctl", "--system"], check=False)
    except Exception:
        pass

    progress.update(task_id, step="[yellow][2/4] Настройка limits.conf (nofile)...[/]", completed=30)
    limits_conf = Path("/etc/security/limits.d/99-android-build.conf")
    limits_content = (
        "# Android build file descriptor limits\n"
        "*  soft  nofile  65535\n"
        "*  hard  nofile  65535\n"
        "root soft  nofile  65535\n"
        "root hard  nofile  65535\n"
    )
    try:
        limits_conf.write_text(limits_content, encoding="utf-8")
    except Exception:
        pass

    progress.update(task_id, step="[yellow][3/4] Настройка pam_limits в /etc/pam.d...[/]", completed=50)
    pam_files = [
        Path("/etc/pam.d/common-session"),
        Path("/etc/pam.d/system-login"),
    ]
    for pam_file in pam_files:
        if pam_file.exists():
            try:
                content = pam_file.read_text(encoding="utf-8")
                if "pam_limits.so" not in content:
                    pam_file.write_text(content.rstrip() + "\nsession required pam_limits.so\n", encoding="utf-8")
            except Exception:
                pass

    progress.update(task_id, step="[yellow][4/4] Настройка env для сборки...[/]", completed=70)
    env_conf = Path("/etc/profile.d/android-build-env.sh")
    env_content = (
        '# Android build environment\n'
        'export USE_CCACHE=1\n'
        'export CCACHE_DIR=~/.ccache\n'
        'ulimit -n 65535 2>/dev/null\n'
    )
    try:
        env_conf.write_text(env_content, encoding="utf-8")
        env_conf.chmod(0o644)
    except Exception:
        pass

def setup_user_environment(progress: Progress, task_id, uid: int, gid: int, ccache_size: str):
    if uid == 0:
        return

    import pwd
    try:
        user_entry = pwd.getpwuid(uid)
    except KeyError:
        return

    user_home = Path(user_entry.pw_dir)
    user_name = user_entry.pw_name
    bashrc = user_home / ".bashrc"

    progress.update(task_id, step=f"[yellow]Настройка .bashrc для {user_name}...[/]", completed=80)

    java_home = Path("/usr/lib/jvm/java-21-openjdk-amd64")
    if not java_home.exists():
        java_home = Path("/usr/lib/jvm/java-17-openjdk-amd64")

    marker_block = "# === Android build env (auto by setup_env.py) ==="
    marker_end = "# === /Android build env ==="

    block_lines = [marker_block]
    if java_home.exists():
        block_lines.append(f'export JAVA_HOME="{java_home}"')
    block_lines += [
        'export PATH="$JAVA_HOME/bin:$PATH"',
        'export USE_CCACHE=1',
        f'export CCACHE_DIR="{user_home / ".ccache"}"',
        'ulimit -n 65535 2>/dev/null',
        marker_end,
        '',
    ]
    block = "\n".join(block_lines)

    try:
        if bashrc.exists():
            content = bashrc.read_text(encoding="utf-8")
            if marker_block in content:
                start = content.index(marker_block)
                end = content.index(marker_end) + len(marker_end)
                content = content[:start] + block + content[end:]
            else:
                content = content.rstrip() + "\n\n" + block
            bashrc.write_text(content, encoding="utf-8")
        else:
            bashrc.write_text(block, encoding="utf-8")
        fix_permissions(bashrc, uid, gid)
    except Exception:
        pass

    if shutil.which("ccache"):
        progress.update(task_id, step=f"[yellow]Конфигурация ccache для {user_name} (-M {ccache_size})...[/]", completed=90)
        ccache_dir = user_home / ".ccache"
        ccache_dir.mkdir(parents=True, exist_ok=True)
        fix_permissions(ccache_dir, uid, gid)
        user_env = os.environ.copy()
        user_env["HOME"] = str(user_home)
        user_env["CCACHE_DIR"] = str(ccache_dir)
        subprocess.run(["ccache", "-M", ccache_size], env=user_env,
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def setup_git_lfs(progress: Progress, task_id, uid: int, gid: int):
    progress.update(task_id, step="[yellow]Инициализация git lfs hooks...[/]", completed=85)
    run_cmd(["git", "lfs", "install"], check=False)

    if uid != 0:
        import pwd
        try:
            user_entry = pwd.getpwuid(uid)
            user_env = os.environ.copy()
            user_env["HOME"] = user_entry.pw_dir
            user_env["USER"] = user_entry.pw_name
            subprocess.run(["git", "lfs", "install"], env=user_env,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

def apt_install_with_retry(packages: list[str], retries: int = 3) -> bool:
    """Устанавливает пакеты через apt с повторными попытками при сетевых ошибках."""
    for attempt in range(1, retries + 1):
        res = run_cmd(["apt-get", "install", "-y", "--no-install-recommends"] + packages, check=False)
        if res.returncode == 0:
            return True
        if attempt < retries:
            console.print(f"[yellow]  Повторная попытка ({attempt}/{retries})...[/]")
            run_cmd(["apt-get", "update", "-qq"], check=False)
    return False

def setup_apt(progress: Progress, task_id, ccache_size: str):
    progress.update(task_id, step="[yellow]Обновление списков репозиториев (apt-get update)...[/]", completed=5)
    run_cmd(["apt-get", "update", "-qq"])

    progress.update(task_id, step="[yellow]Проверка поддержки i386 архитектуры...[/]", completed=8)
    dpkg_arch = run_cmd(["dpkg", "--print-architecture"], check=False, suppress=False, capture=True)
    if dpkg_arch.returncode == 0 and dpkg_arch.stdout and "amd64" in dpkg_arch.stdout.decode().strip():
        run_cmd(["dpkg", "--add-architecture", "i386"], check=False)
        run_cmd(["apt-get", "update", "-qq"], check=False)

    core = [
        "git", "git-core", "gnupg", "flex", "bison", "build-essential", "zip", "curl",
        "zlib1g-dev", "libssl-dev", "bc", "rsync", "unzip", "python3", "python-is-python3",
        "ccache", "schedtool", "lzop", "imagemagick", "pngcrush", "git-lfs", "gperf",
        "bzip2", "patch", "hostname", "file",
    ]
    progress.update(task_id, step="[yellow][1/6] Установка базовых утилит...[/]", completed=15)
    apt_install_with_retry(core)

    multilib = [
        "gcc-multilib", "g++-multilib", "libc6-dev-i386",
        "lib32z1-dev", "lib32ncurses5-dev", "lib32readline-dev", "lib32stdc++-dev",
    ]
    progress.update(task_id, step="[yellow][2/6] Установка multilib (i386) пакетов...[/]", completed=30)
    apt_install_with_retry(multilib)

    libs = [
        "libncurses5", "libncurses6", "libncurses-dev", "libtinfo5",
        "libelf-dev", "libbz2-dev", "libxml2-utils", "libxslt1-dev",
        "libgl1-mesa-dev", "x11proto-core-dev", "libx11-dev", "libxext-dev",
        "xsltproc", "fontconfig",
    ]
    progress.update(task_id, step="[yellow][3/6] Установка библиотек разработки...[/]", completed=50)
    apt_install_with_retry(libs)

    java = ["openjdk-17-jdk", "openjdk-21-jdk"]
    progress.update(task_id, step="[yellow][4/6] Установка OpenJDK 17/21...[/]", completed=65)
    apt_install_with_retry(java)

    progress.update(task_id, step="[yellow][5/6] Установка утилит Android (sparse/fsutils)...[/]", completed=75)
    if not apt_install_with_retry(["android-sdk-libsparse-utils"], retries=1):
        apt_install_with_retry(["android-tools-fsutils"], retries=1)

    progress.update(task_id, step="[yellow][6/6] Настройка symlinks, ccache, JAVA_HOME...[/]", completed=85)

    lib64 = Path("/usr/lib/x86_64-linux-gnu")
    if lib64.exists():
        for src_name, dst_name in [("libncurses.so.6", "libncurses.so.5"), ("libtinfo.so.6", "libtinfo.so.5")]:
            src, dst = lib64 / src_name, lib64 / dst_name
            if not dst.exists() and src.exists():
                try:
                    dst.symlink_to(src)
                except OSError:
                    pass

    if shutil.which("ccache"):
        run_cmd(["ccache", "-M", ccache_size], check=False)

    java_home_candidate = Path("/usr/lib/jvm/java-21-openjdk-amd64")
    if not java_home_candidate.exists():
        java_home_candidate = Path("/usr/lib/jvm/java-17-openjdk-amd64")
    if java_home_candidate.exists():
        profile_d = Path("/etc/profile.d/android-java.sh")
        try:
            profile_d.write_text(f'export JAVA_HOME="{java_home_candidate}"\n', encoding="utf-8")
            profile_d.chmod(0o644)
        except Exception:
            pass

    progress.update(task_id, step="[bold green]✓ Пакеты APT установлены[/]", completed=100)

def setup_fedora(progress: Progress, task_id, ccache_size: str):
    dnf_cmd = "dnf5" if shutil.which("dnf5") else "dnf"
    
    progress.update(task_id, step="[yellow]Проверка конфигурации DNF (i686 exclude)...[/]", completed=10)
    dnf_conf = Path("/etc/dnf/dnf.conf")
    if dnf_conf.exists():
        try:
            content = dnf_conf.read_text()
            if "exclude=" in content and "i686" in content:
                new_lines = []
                for line in content.splitlines():
                    if line.strip().startswith("exclude=") and "i686" in line:
                        new_lines.append(f"#{line}")
                    else:
                        new_lines.append(line)
                dnf_conf.write_text("\n".join(new_lines))
        except Exception:
            pass

    progress.update(task_id, step="[yellow]Обновление системных метаданных и групп...[/]", completed=25)
    run_cmd([dnf_cmd, "upgrade", "--refresh", "-y"], check=False)
    run_cmd([dnf_cmd, "install", "-y", "--skip-broken", "@Development Tools", "@C Development Tools and Libraries"], check=False)

    pkgs = [
        "git-core", "gnupg", "flex", "bison", "gperf", "zlib-devel",
        "glibc-devel.i686", "libstdc++.i686", "ncurses-devel.i686",
        "libX11-devel", "libX11-devel.i686", "mesa-libGL-devel.i686",
        "libxml2-devel", "libxslt-devel", "openssl-devel",
        "zip", "unzip", "curl", "python3", "lzop", "schedtool", "pngcrush", "ccache", "optipng",
        "git-lfs", "perl-Digest-SHA", "which", "ncurses-compat-libs",
        "clang", "llvm", "lld", "libxcrypt-compat", "ncurses-devel",
        "readline-devel", "libffi-devel", "elfutils-libelf-devel",
        "bc", "rsync", "bzip2", "patch", "hostname", "perl-FindBin", "perl-File-Compare",
        "android-tools"
    ]

    progress.update(task_id, step="[yellow]Установка основных пакетов DNF...[/]", completed=55)
    run_cmd([dnf_cmd, "install", "-y", "--skip-broken"] + pkgs, check=False)

    progress.update(task_id, step="[yellow]Установка OpenJDK...[/]", completed=75)
    res = run_cmd([dnf_cmd, "install", "-y", "java-21-openjdk-devel"], check=False)
    if res.returncode != 0:
        run_cmd([dnf_cmd, "install", "-y", "java-17-openjdk-devel"], check=False)

    progress.update(task_id, step="[yellow]Проверка системных symlinks и python...[/]", completed=85)
    lib64 = Path("/usr/lib64")
    if lib64.exists():
        nc6 = lib64 / "libncurses.so.6"
        nc5 = lib64 / "libncurses.so.5"
        tf6 = lib64 / "libtinfo.so.6"
        tf5 = lib64 / "libtinfo.so.5"
        
        if not nc5.exists() and nc6.exists():
            try:
                nc5.symlink_to(nc6)
            except OSError:
                pass
        if not tf5.exists() and tf6.exists():
            try:
                tf5.symlink_to(tf6)
            except OSError:
                pass

    if not shutil.which("python"):
        py3 = shutil.which("python3")
        if py3:
            try:
                Path("/usr/bin/python").symlink_to(py3)
            except OSError:
                pass

    if shutil.which("ccache"):
        progress.update(task_id, step=f"[yellow]Конфигурация ccache (-M {ccache_size})...[/]", completed=95)
        run_cmd(["ccache", "-M", ccache_size], check=False)

def setup_pacman(progress: Progress, task_id):
    progress.update(task_id, step="[yellow]Проверка /etc/pacman.conf ([multilib])...[/]", completed=10)
    pacman_conf = Path("/etc/pacman.conf")
    if pacman_conf.exists():
        content = pacman_conf.read_text()
        if "[multilib]" not in content:
            with open(pacman_conf, "a", encoding="utf-8") as f:
                f.write("\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n")

    progress.update(task_id, step="[yellow]Синхронизация баз данных pacman...[/]", completed=30)
    run_cmd(["pacman", "-Sy", "--noconfirm"])

    pkgs = [
        "base-devel", "multilib-devel", "gcc", "clang", "git", "git-lfs",
        "cmake", "ninja", "python", "jdk17-openjdk", "jdk21-openjdk", "gperf", "libxml2",
        "unzip", "zip", "curl", "rsync", "schedtool", "perl", "bc", "lzop", "imagemagick",
        "ncurses", "lib32-ncurses", "lib32-readline", "lib32-zlib", "libxslt", "pngcrush",
        "android-tools"
    ]

    progress.update(task_id, step="[yellow]Установка пакетов Pacman...[/]", completed=70)
    run_cmd(["pacman", "-S", "--needed", "--noconfirm"] + pkgs)

    progress.update(task_id, step="[yellow]Настройка ccache...[/]", completed=90)
    if shutil.which("ccache"):
        run_cmd(["ccache", "-M", "80G"], check=False)

# ============================================================
# 5. Установка repo и глобальная настройка Git
# ============================================================
def setup_repo_and_git(progress: Progress, task_id, git_user: str, git_email: str, uid: int, gid: int):
    progress.update(task_id, step="[yellow]Проверка и установка утилиты repo...[/]", completed=20)
    repo_path = Path("/usr/local/bin/repo")
    if not repo_path.exists() or not shutil.which("repo"):
        curl_cmd = ["curl", "-s", "https://storage.googleapis.com/git-repo-downloads/repo"]
        res = subprocess.run(curl_cmd, capture_output=True)
        if res.returncode == 0 and res.stdout:
            repo_path.write_bytes(res.stdout)
            repo_path.chmod(0o755)

    progress.update(task_id, step="[yellow]Настройка конфигураций Git...[/]", completed=60)
    
    def apply_git_config(env=None):
        subprocess.run(["git", "config", "--global", "http.postBuffer", "524288000"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        check_name = subprocess.run(["git", "config", "--global", "user.name"], capture_output=True, text=True, env=env)
        if not check_name.stdout.strip():
            subprocess.run(["git", "config", "--global", "user.name", git_user], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
        check_email = subprocess.run(["git", "config", "--global", "user.email"], capture_output=True, text=True, env=env)
        if not check_email.stdout.strip():
            subprocess.run(["git", "config", "--global", "user.email", git_email], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Применяем для root
    apply_git_config()
    
    # Применяем для вызывающего sudo пользователя
    if uid != 0:
        import pwd
        try:
            user_entry = pwd.getpwuid(uid)
            user_env = os.environ.copy()
            user_env["HOME"] = user_entry.pw_dir
            user_env["USER"] = user_entry.pw_name
            apply_git_config(env=user_env)
            
            gitconfig_path = Path(user_entry.pw_dir) / ".gitconfig"
            if gitconfig_path.exists():
                fix_permissions(gitconfig_path, uid, gid)
        except Exception:
            pass

    progress.update(task_id, step="[bold green]✓ Repo и Git настроены[/]", completed=100)

# ============================================================
# 6. Главная точка входа
# ============================================================
def main():
    parser = argparse.ArgumentParser(description="Android Build Environment Setup Tool")
    parser.add_argument("--ccache-size", default="80G", help="Размер кэша ccache (по умолчанию: 80G)")
    parser.add_argument("--git-user", default="Android Builder", help="Имя по умолчанию для git user.name")
    parser.add_argument("--git-email", default="bot@localhost", help="Email по умолчанию для git user.email")
    parser.add_argument("--force", action="store_true", help="Принудительный повторный запуск (игнорировать маркер)")
    args = parser.parse_args()

    uid, gid = get_target_uid_gid()
    os_info = get_os_info()
    os_id = os_info.get("ID", "").lower()
    os_like = os_info.get("ID_LIKE", "").lower()

    console.print(Panel("[bold cyan]Настройка системного окружения для сборки Android ROM[/bold cyan]", expand=False))

    if is_already_setup() and not args.force:
        console.print("[bold green]Окружение уже настроено.[/] Пропуск. (используйте --force для повторной настройки)\n")
        sys.exit(0)

    check_disk_space()

    MULTI_PROGRESS_COLUMNS = [
        SpinnerColumn(),
        TextColumn("{task.description}"),
        BarColumn(bar_width=30),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TextColumn("• {task.fields[step]}"),
    ]

    with Progress(*MULTI_PROGRESS_COLUMNS, console=console) as progress:
        sys_task = progress.add_task("[cyan]Системные пакеты   [/]", total=100, step="Инициализация")
        limits_task = progress.add_task("[cyan]Системные лимиты  [/]", total=100, step="Инициализация")
        git_task = progress.add_task("[cyan]Repo & Git Config  [/]", total=100, step="Инициализация")
        user_task = progress.add_task("[cyan]Пользователь      [/]", total=100, step="Инициализация")

        # 1. Системные пакеты
        try:
            if any(dist in os_id or dist in os_like for dist in ["ubuntu", "debian", "mint", "pop", "kali", "parrot"]):
                progress.update(sys_task, step="[yellow]Определение: семейство Debian/Ubuntu[/]")
                setup_apt(progress, sys_task, args.ccache_size)
            elif any(dist in os_id or dist in os_like for dist in ["fedora", "centos", "rhel", "almalinux", "rocky"]):
                progress.update(sys_task, step="[yellow]Определение: семейство Fedora/RHEL[/]")
                setup_fedora(progress, sys_task, args.ccache_size)
            elif any(dist in os_id or dist in os_like for dist in ["arch", "manjaro", "endeavouros"]):
                progress.update(sys_task, step="[yellow]Определение: семейство Arch Linux[/]")
                setup_pacman(progress, sys_task)
            else:
                progress.update(sys_task, step="[red]Неизвестный дистрибутив. Пропуск пакетов.[/]", completed=100)
                console.print(f"[bold red]Предупреждение:[/] Не удалось автоопределить менеджер пакетов для ОС '{os_id}'.")
            
            progress.update(sys_task, step="[bold green]✓ Пакеты успешно установлены[/]", completed=100)
        except Exception as e:
            progress.update(sys_task, step=f"[bold red]Ошибка установки: {e}[/]", completed=100)
            console.print(f"[bold red]Сбой при установке пакетов:[/] {e}")
            sys.exit(1)

        # 2. Системные лимиты (sysctl, limits, pam)
        try:
            setup_system_limits(progress, limits_task, uid, gid)
            progress.update(limits_task, step="[bold green]✓ Лимиты настроены[/]", completed=100)
        except Exception as e:
            progress.update(limits_task, step=f"[bold red]Ошибка: {e}[/]", completed=100)
            console.print(f"[bold red]Сбой настройки лимитов:[/] {e}")

        # 3. Repo, Git, git lfs
        try:
            setup_repo_and_git(progress, git_task, args.git_user, args.git_email, uid, gid)
            setup_git_lfs(progress, git_task, uid, gid)
            progress.update(git_task, step="[bold green]✓ Repo, Git, LFS настроены[/]", completed=100)
        except Exception as e:
            progress.update(git_task, step=f"[bold red]Ошибка настройки: {e}[/]", completed=100)
            console.print(f"[bold red]Сбой при настройке Repo/Git:[/] {e}")
            sys.exit(1)

        # 4. Пользовательская среда (.bashrc, JAVA_HOME, ccache)
        try:
            setup_user_environment(progress, user_task, uid, gid, args.ccache_size)
            progress.update(user_task, step="[bold green]✓ Среда пользователя настроена[/]", completed=100)
        except Exception as e:
            progress.update(user_task, step=f"[bold red]Ошибка: {e}[/]", completed=100)
            console.print(f"[bold red]Сбой настройки среды:[/] {e}")

    mark_setup_done()
    console.print("\n[bold green]✓ Системное окружение полностью готово к сборке![/bold green]")
    console.print("[dim]  Перезайдите в терминал или выполните: source ~/.bashrc[/]\n")

if __name__ == "__main__":
    main()