#!/bin/bash

# ============================================================
# Глобальные переменные и Конфигурация
# ============================================================
BAK_ROOT="bakFiles"
ORIG_DIR="$BAK_ROOT/original"
NEW_FILES_LIST="$BAK_ROOT/newFiles.txt" # Файл со списком путей для сохранения
QUEUE_SAVE_DIR="$BAK_ROOT/build_files" # Папка для сохранённых очередей сборок
SNAPSHOT_DIR=""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

backup_storage_path() {
    local rel_path="$1"

    case "$(basename "$rel_path")" in
        Android.bp|Android.mk)
            printf '%s' "${rel_path}.bak"
            ;;
        *)
            printf '%s' "$rel_path"
            ;;
    esac
}

backup_tree_path() {
    local stored_path="$1"

    case "$stored_path" in
        Android.bp.bak|*/Android.bp.bak|Android.mk.bak|*/Android.mk.bak)
            printf '%s' "${stored_path%.bak}"
            ;;
        *)
            printf '%s' "$stored_path"
            ;;
    esac
}

is_back_input() {
    local value="${1,,}"

    [[ "$value" == "b" || "$value" == "back" || "$value" == "назад" ]]
}

is_yes_default_input() {
    local value="${1,,}"

    [[ -z "$value" || "$value" == "y" || "$value" == "yes" || "$value" == "д" || "$value" == "да" ]]
}

is_no_input() {
    local value="${1,,}"

    [[ "$value" == "n" || "$value" == "no" || "$value" == "н" || "$value" == "нет" ]]
}

# Флаги состояния
DO_SYNC=false
FORCE_SYNC_ONLY=false # --forcesync
DO_BUILD=false
DO_CLEAN=false
DO_SETUP_ENV=false
FORCE_ENV=false
FORCE_LUNCH=false
SYNC_DRIVE=false        # --sync-drive
SYNC_DRIVE_RELEASE=false # --sync-drive-release
DRIVE_RELEASE_DATE=""   # Optional date/all for --sync-drive-release
DO_CLEAN_DEVICE=false
DO_KILL=false
DO_REP=false
SYNC_SF=false          # --sync-sf
SF_STOCK_KERNEL_IMG="" # --sf-stock-kernel
SF_OUT_DIR=""          # --out-sf-dir
SF_UPLOAD_JOBS="${SF_UPLOAD_JOBS:-4}" # Параллельные rsync-задачи для SourceForge
GDRIVE_ROOT="${GDRIVE_ROOT:-$HOME/GoogleDrive/evox}" # Локальная папка Google Drive
GDRIVE_COPY_JOBS="${GDRIVE_COPY_JOBS:-4}" # Параллельные copy-задачи для Google Drive
# Параметры
JOBS=""
DEVICE_CODE=""
BUILD_TYPE="" # Default: userdebug
APP_TARGET="" # --app
VERSION_PART="bp4a" # --version (default)

# Список целевых устройств для интерактивного меню
DEVICES=("shiba" "husky" "akita" "peridot" "gts7xlwifi")
DO_RELEASE=false


# for kernel in "bp4a.251105.015-zuma_A16_Sultan_WKSU_SUSFS-v2.0.0-r2" "bp4a.251105.015-SukiSU-37714-zuma_A16_Sultan-20250909_SUSFS-v2.0.0-r12" "bp4a.251105.015-StockKernel" ; do
#     for d in husky shiba akita ; do 
#         . ./make.sh -j 16 --build $d user --kernel "${d}-bp4a.251105.015-zuma_A16_Sultan_WKSU_SUSFS-v2.0.0-r2" --clean-device --sync-drive
#         . ./make.sh -j 16 --build $d user --kernel "${d}-bp4a.251105.015-SukiSU-37714-zuma_A16_Sultan-20250909_SUSFS-v2.0.0-r12" --clean-device --sync-drive
#         . ./make.sh -j 16 --build $d user --kernel "${d}-bp4a.251105.015-StockKernel" --clean-device --sync-drive
#     done
# done
safe_exit() {
    local code=${1:-1}
    # Проверка: если скрипт запущен через source, используем return
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        return "$code" 2>/dev/null || exit "$code"
    else
        exit "$code"
    fi
}

show_help() {
    echo -e "${BLUE}Android Build Wrapper (v2.2)${NC}"
    echo -e "Использование: ${GREEN}source ./make.sh [ОПЦИИ] [DEVICE] [TYPE]${NC}"
    echo ""
    echo -e "${YELLOW}Окружение:${NC}"
    echo -e "  --setup-env      : Установить пакеты и зависимости (apt/dnf/pacman)."
    echo ""
    echo -e "${YELLOW}Синхронизация:${NC}"
    echo -e "  --sync           : Умная синхронизация (Backup -> Revert -> Sync -> Patch)."
    echo -e "  --forcesync      : Просто жесткий 'repo sync' (без патчей и бекапов)."
    echo -e "  --rep            : Восстановить изменения из последнего snapshot после прерванного sync."
    echo -e "  -j <num>         : Потоки."
    echo ""
    echo -e "${YELLOW}Ядро (Kernel):${NC}"
    echo -e "  --kernel <dir>   : Указать папку ядра (в device/google/pixel-kernels)."
    echo -e "  --prebuild-kernel: Режим сборки с prebuilt ядрами."
    echo -e "  --ls-kernel      : Показать список доступных ядер."
    echo ""
    echo -e "${YELLOW}Сборка и Выгрузка:${NC}"
    echo -e "  --build          : Активировать сборку."
    echo -e "  --app <name>     : Сбилдить конкретное приложение/модуль (требует --build)."
    echo -e "  --clean          : Полная очистка (m clean)."
    echo -e "  --clean-device   : Очистить только папку устройства (rm -rf out/target/product/DEVICE)."
    echo -e "  --kill           : Убить все процессы сборки и очистить lock-файлы."
    echo -e "  --sync-drive     : Авто-копирование последнего ZIP и образов в ~/GoogleDrive/evox после успеха (GDrive-only)."
    echo -e "  --sync-drive-release [date|all]: Скопировать существующие release-файлы из device/google/release в GDrive (без date = последняя)."
    echo -e "  --sync-sf        : Загрузить ZIP, образы (recovery/) и boot_stock.img на SourceForge после сборки + автосинк в GDrive."
    echo -e "  --sf-stock-kernel <path>: Путь к boot.img для загрузки как boot_stock.img (recovery/) на SF."
    echo -e "  --out-sf-dir <name>     : Подкаталог внутри device/date/ на SF (для разделения сборок с разными ядрами)."
    echo -e "  GDRIVE_ROOT=/path       : Переопределить папку GDrive (def: ~/GoogleDrive/evox)."
    echo -e "  GDRIVE_COPY_JOBS=<num>  : Параллельные copy-задачи для GDrive (def: 4)."
    echo -e "  --env            : Force source build/envsetup.sh."
    echo -e "  --lunch          : Force lunch."
    echo -e "  --version <ver>  : Версия платформы в lunch (def: bp4a)."
    echo ""
    echo -e "${YELLOW}Аргументы:${NC}"
    echo -e "  DEVICE           : Codename (shiba, stone)."
    echo -e "  TYPE             : user, userdebug, eng (def: userdebug)."
    echo ""
}

# ============================================================
# Функция установки зависимостей
# ============================================================
kill_build() {
    echo -e "${YELLOW}=== KILL: Остановка всех процессов сборки ===${NC}"

    # Убиваем процессы сборки
    local PROCS=("soong_build" "ninja" "ckati" "make" "javac" "d8" "r8" "metalava" "ziptime" "signapk" "aapt2" "zipalign")
    local KILLED=0
    for proc in "${PROCS[@]}"; do
        local PIDS=$(pgrep -f "$proc" 2>/dev/null | grep -v $$ || true)
        if [ -n "$PIDS" ]; then
            echo -e "  Killing $proc (PIDs: $(echo $PIDS | tr '\n' ' '))..."
            echo "$PIDS" | xargs kill -9 2>/dev/null || true
            KILLED=$((KILLED + $(echo "$PIDS" | wc -w)))
        fi
    done

    # Убиваем Java процессы связанные со сборкой
    local JAVA_PIDS=$(pgrep -f 'java.*soong\|java.*turbine\|java.*metalava\|java.*gradle' 2>/dev/null || true)
    if [ -n "$JAVA_PIDS" ]; then
        echo -e "  Killing Java build processes..."
        echo "$JAVA_PIDS" | xargs kill -9 2>/dev/null || true
        KILLED=$((KILLED + $(echo "$JAVA_PIDS" | wc -w)))
    fi

    # Очистка lock-файлов
    echo -e "${YELLOW}--> Очистка lock-файлов...${NC}"
    local LOCKS_REMOVED=0
    local LOCK_PATHS=(
        "out/.lock"
        "out/soong/.lock"
        "out/soong/build.ninja.lock"
        # "out/.ninja_log"
        # "out/.ninja_deps"
        "out/soong/.soong.lock"
        "out/soong/.bootstrap/build.ninja.lock"
        "out/.module_paths/*.lock"
    )
    for lock in "${LOCK_PATHS[@]}"; do
        for f in $lock; do
            if [ -e "$f" ]; then
                rm -f "$f"
                echo "  Removed: $f"
                LOCKS_REMOVED=$((LOCKS_REMOVED + 1))
            fi
        done
    done

    # Очистка Soong UI fifo/pipe
    # if [ -d "out/.ninja_fifo" ]; then
    #     rm -rf "out/.ninja_fifo"
    #     echo "  Removed: out/.ninja_fifo"
    #     LOCKS_REMOVED=$((LOCKS_REMOVED + 1))
    # fi

    # Очистка kati stamp (может блокировать повторный запуск)
    # find out/ -name ".kati_stamp*" -delete 2>/dev/null && echo "  Removed: .kati_stamp files"

    echo -e "${GREEN}=== KILL: Готово. Убито процессов: $KILLED, удалено lock-файлов: $LOCKS_REMOVED ===${NC}"
}

# ============================================================
run_env_setup() {
    echo -e "${BLUE}=== ANDROID BUILD ENV SETUP ===${NC}"

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR] Для установки пакетов нужны права root (sudo).${NC}"
        return 1
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_LIKE=$ID_LIKE
    else
        echo -e "${RED}[ERROR] Не могу определить ОС.${NC}"
        return 1
    fi

    # --- Внутренние функции установки ---
    _install_apt() {
        echo -e "${YELLOW}[APT] Установка зависимостей...${NC}"
        apt-get update
        local DEPS="git git-core gnupg flex bison build-essential zip curl zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev \
        x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
        xsltproc unzip fontconfig python3 python-is-python3 rsync schedtool \
        libssl-dev bc ccache libncurses6 libncurses-dev libelf-dev \
        imagemagick lzop pngcrush git-lfs openjdk-17-jdk openjdk-21-jdk"
        apt-get install -y $DEPS
        
        if [ ! -f /usr/lib/x86_64-linux-gnu/libncurses.so.5 ]; then
             ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5 || true
             ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5 || true
        fi
    }

    _install_fedora() {
        echo -e "${YELLOW}[DNF] Обнаружена Fedora ($OS_ID). Настройка окружения для Android 16 QPR1...${NC}"
        local DNF_CMD="dnf"
        if command -v dnf5 &> /dev/null; then DNF_CMD="dnf5"; fi

        # Убираем исключение i686 библиотек
        if [ -f /etc/dnf/dnf.conf ] && grep -q "exclude=.*i686" /etc/dnf/dnf.conf; then
            sudo sed -i 's/^exclude=/#exclude=/g' /etc/dnf/dnf.conf
        fi

        sudo $DNF_CMD upgrade --refresh -y
        sudo $DNF_CMD install -y --skip-broken @"Development Tools" @"C Development Tools and Libraries" || true

        # Пакеты из вашего списка + критические дополнения для A16/SM8250
        local PKGS="git-core gnupg flex bison gperf zlib-devel \
        glibc-devel.i686 libstdc++.i686 ncurses-devel.i686 \
        libX11-devel libX11-devel.i686 mesa-libGL-devel.i686 \
        libxml2-devel libxslt-devel openssl-devel \
        zip unzip curl python3 lzop schedtool pngcrush ccache optipng \
        git-lfs perl-Digest-SHA which ncurses-compat-libs \
        clang llvm lld libxcrypt-compat ncurses-devel \
        readline-devel libffi-devel elfutils-libelf-devel \
        bc rsync bzip2 patch hostname perl-FindBin perl-File-Compare"
        
        sudo $DNF_CMD install -y --skip-broken $PKGS
        sudo $DNF_CMD install -y java-21-openjdk-devel || sudo $DNF_CMD install -y java-17-openjdk-devel

        # Фикс для библиотек ncurses (чтобы старые тулзы видели 5-ю версию)
        if [ ! -f /usr/lib64/libncurses.so.5 ]; then
            sudo ln -sf /usr/lib64/libncurses.so.6 /usr/lib64/libncurses.so.5 || true
            sudo ln -sf /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5 || true
        fi

        # Фикс для скриптов ядра, которые все еще вызывают 'python' вместо 'python3'
        if ! command -v python &> /dev/null; then
            sudo ln -sf /usr/bin/python3 /usr/bin/python || true
        fi

        ccache -M 80G
        echo -e "${GREEN}Настройка Fedora завершена.${NC}"
    }

    _install_pacman() {
        echo -e "${YELLOW}[PACMAN] Установка...${NC}"
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            echo "[multilib]" >> /etc/pacman.conf
            echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
        fi
        pacman -Sy --noconfirm
        pacman -S --needed --noconfirm base-devel multilib-devel gcc clang git git-lfs \
        cmake ninja python jdk17-openjdk jdk21-openjdk gperf libxml2 unzip zip curl \
        rsync schedtool perl bc lzop imagemagick ncurses lib32-ncurses lib32-readline \
        lib32-zlib libxslt pngcrush
    }

    case "$OS_ID" in
        ubuntu|debian|linuxmint|pop|kali|parrot) _install_apt ;;
        arch|manjaro|endeavouros) _install_pacman ;;
        *fedora*|centos|rhel|almalinux|rocky) _install_fedora ;;
        *) echo -e "${RED}Дистрибутив не распознан авто-установщиком.${NC}"; return 1 ;;
    esac

    if ! command -v repo &> /dev/null; then
        echo -e "${YELLOW}Установка repo...${NC}"
        curl -s https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
        chmod a+x /usr/local/bin/repo
    fi

    if [ -z "$(git config --global user.name)" ]; then
        git config --global user.name "Android Builder"
        git config --global user.email "bot@localhost"
    fi
    git config --global http.postBuffer 524288000
    echo -e "${GREEN}Настройка окружения завершена!${NC}"
}

# ============================================================
# Основная логика (MAIN)
# ============================================================
export TARGET_KERNEL_DIR_EXT=""

KERNEL_BASE_PATH_PIXEL="device/google/pixel-kernels"

function list_available_kernels() {
    if [ -d "$1" ]; then
        echo "================================================="
        echo "📦 Доступные каталоги ядер в $1/:"
        echo "================================================="
        # Ищем папки, фильтруем лишнее и добавляем сортировку по имени
        find "$1" -maxdepth 1 -mindepth 1 -type d -printf "%P\n" | \
            grep -vE "\.git|anykernels" | \
            sort | \
            sed 's/^/  - /'
        echo "================================================="
    else
        echo "❌ Ошибка: Базовая директория ядер '$1' не найдена."
        return 1
    fi
}

# ============================================================
# Интерактивное меню выбора параметров сборки
# ============================================================
interactive_build_menu() {
    echo -e "\n${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e   "${BLUE}║      Интерактивный режим сборки      ║${NC}"
    echo -e   "${BLUE}╚══════════════════════════════════════╝${NC}"

    echo -e "${YELLOW}Подсказка:${NC} на шагах ввода можно набрать ${GREEN}b${NC}, ${GREEN}back${NC} или ${GREEN}назад${NC}."

    local _build_types=("user" "userdebug" "eng")
    local _step=1

    while true; do
        case "$_step" in
            1)
                echo -e "\n${YELLOW}[1] Выберите устройство:${NC}"
                for i in "${!DEVICES[@]}"; do
                    echo -e "    $((i+1))) ${DEVICES[$i]}"
                done

                local _current_dev_idx=""
                for i in "${!DEVICES[@]}"; do
                    if [ "${DEVICES[$i]}" = "$DEVICE_CODE" ]; then
                        _current_dev_idx=$((i+1))
                        break
                    fi
                done

                local _dev_choice
                while true; do
                    local _dev_prompt="  Номер (1-${#DEVICES[@]}"
                    [ -n "$_current_dev_idx" ] && _dev_prompt="${_dev_prompt}; Enter = $DEVICE_CODE"
                    _dev_prompt="${_dev_prompt}): "
                    read -rp "$_dev_prompt" _dev_choice

                    if is_back_input "$_dev_choice"; then
                        echo -e "${YELLOW}  Это первый пункт, назад некуда.${NC}"
                        continue
                    fi
                    [ -z "$_dev_choice" ] && [ -n "$_current_dev_idx" ] && _dev_choice="$_current_dev_idx"
                    if [[ "$_dev_choice" =~ ^[0-9]+$ ]] && \
                       [ "$_dev_choice" -ge 1 ] && [ "$_dev_choice" -le "${#DEVICES[@]}" ]; then
                        break
                    fi
                    echo -e "${RED}  Неверный ввод, повторите.${NC}"
                done

                local _new_device="${DEVICES[$((_dev_choice-1))]}"
                if [ "$_new_device" != "$DEVICE_CODE" ]; then
                    export TARGET_KERNEL_DIR_EXT=""
                    SF_STOCK_KERNEL_IMG=""
                    SF_OUT_DIR=""
                fi
                DEVICE_CODE="$_new_device"
                echo -e "  ${GREEN}→ Устройство: $DEVICE_CODE${NC}"
                _step=2
                ;;

            2)
                echo -e "\n${YELLOW}[2] Выберите тип сборки:${NC}"
                for i in "${!_build_types[@]}"; do
                    echo -e "    $((i+1))) ${_build_types[$i]}"
                done

                local _default_type_idx=1
                for i in "${!_build_types[@]}"; do
                    if [ "${_build_types[$i]}" = "$BUILD_TYPE" ]; then
                        _default_type_idx=$((i+1))
                        break
                    fi
                done

                local _type_choice
                while true; do
                    read -rp "  Номер [${_default_type_idx}], b = назад: " _type_choice
                    if is_back_input "$_type_choice"; then
                        _step=1
                        continue 2
                    fi
                    _type_choice="${_type_choice:-$_default_type_idx}"
                    if [[ "$_type_choice" =~ ^[0-9]+$ ]] && \
                       [ "$_type_choice" -ge 1 ] && [ "$_type_choice" -le "${#_build_types[@]}" ]; then
                        break
                    fi
                    echo -e "${RED}  Неверный ввод, повторите.${NC}"
                done
                BUILD_TYPE="${_build_types[$((_type_choice-1))]}"
                echo -e "  ${GREEN}→ Тип: $BUILD_TYPE${NC}"
                _step=3
                ;;

            3)
                local _default_jobs
                _default_jobs=$(nproc 2>/dev/null || echo "8")
                local _jobs_default="${JOBS#-j}"
                [[ "$_jobs_default" =~ ^[0-9]+$ ]] || _jobs_default="$_default_jobs"

                local _jobs_input
                while true; do
                    read -rp "$(echo -e "\n${YELLOW}[3]${NC} Количество потоков [${_jobs_default}], b = назад: ")" _jobs_input
                    if is_back_input "$_jobs_input"; then
                        _step=2
                        continue 2
                    fi
                    _jobs_input="${_jobs_input:-$_jobs_default}"
                    if [[ "$_jobs_input" =~ ^[0-9]+$ ]] && [ "$_jobs_input" -gt 0 ]; then
                        break
                    fi
                    echo -e "${RED}  Неверный ввод, повторите.${NC}"
                done
                JOBS="-j${_jobs_input}"
                echo -e "  ${GREEN}→ Потоки: $JOBS${NC}"
                _step=4
                ;;

            4)
                echo -e "\n${YELLOW}[4] Выберите ядро (фильтр: ${DEVICE_CODE}):${NC}"
                local _kernel_list
                _kernel_list=$(find "$KERNEL_BASE_PATH_PIXEL" -maxdepth 1 -mindepth 1 -type d -printf "%P\n" 2>/dev/null \
                    | grep -vE "\.git|anykernels" \
                    | grep -i "$DEVICE_CODE" \
                    | sort)

                if [ -z "$_kernel_list" ]; then
                    echo -e "  ${YELLOW}Ядра для '$DEVICE_CODE' не найдены.${NC}"
                    local _kern_empty
                    read -rp "  Enter = стоковое, b = назад: " _kern_empty
                    if is_back_input "$_kern_empty"; then
                        _step=3
                        continue
                    fi
                    export TARGET_KERNEL_DIR_EXT=""
                    echo -e "  ${GREEN}→ Ядро: стоковое${NC}"
                else
                    echo -e "    0) -- Без кастомного ядра (стоковое) --"
                    local _kernel_arr=()
                    local _kidx=1
                    local _default_kchoice=0
                    while IFS= read -r _kname; do
                        [ -z "$_kname" ] && continue
                        echo -e "    ${_kidx}) ${_kname}"
                        _kernel_arr+=("$_kname")
                        if [ "$_kname" = "$TARGET_KERNEL_DIR_EXT" ]; then
                            _default_kchoice=$_kidx
                        fi
                        ((_kidx++))
                    done <<< "$_kernel_list"

                    local _kern_choice
                    while true; do
                        read -rp "  Номер [${_default_kchoice}], b = назад: " _kern_choice
                        if is_back_input "$_kern_choice"; then
                            _step=3
                            continue 2
                        fi
                        _kern_choice="${_kern_choice:-$_default_kchoice}"
                        if [[ "$_kern_choice" =~ ^[0-9]+$ ]] && \
                           [ "$_kern_choice" -ge 0 ] && [ "$_kern_choice" -lt "$_kidx" ]; then
                            break
                        fi
                        echo -e "${RED}  Неверный ввод, повторите.${NC}"
                    done

                    if [ "$_kern_choice" -eq 0 ]; then
                        export TARGET_KERNEL_DIR_EXT=""
                        echo -e "  ${GREEN}→ Ядро: стоковое${NC}"
                    else
                        export TARGET_KERNEL_DIR_EXT="${_kernel_arr[$((_kern_choice-1))]}"
                        echo -e "  ${GREEN}→ Ядро: $TARGET_KERNEL_DIR_EXT${NC}"
                    fi
                fi
                _step=5
                ;;

            5)
                local _rel_choice
                while true; do
                    read -rp "$(echo -e "\n${YELLOW}[5]${NC} Сохранить релиз в device/google/release/? [Y/n, b = назад]: ")" _rel_choice
                    if is_back_input "$_rel_choice"; then
                        _step=4
                        continue 2
                    fi
                    if is_no_input "$_rel_choice"; then
                        DO_RELEASE=false
                        echo -e "  ${YELLOW}→ Release: выкл${NC}"
                        break
                    fi
                    if is_yes_default_input "$_rel_choice"; then
                        DO_RELEASE=true
                        echo -e "  ${GREEN}→ Release: ВКЛ${NC}"
                        break
                    fi
                    echo -e "${RED}  Введите y/yes, n/no или b/back.${NC}"
                done
                _step=6
                ;;

            6)
                local _clean_choice
                while true; do
                    read -rp "$(echo -e "\n${YELLOW}[6]${NC} Очистить out-папку устройства перед сборкой? [Y/n, b = назад]: ")" _clean_choice
                    if is_back_input "$_clean_choice"; then
                        _step=5
                        continue 2
                    fi
                    if is_no_input "$_clean_choice"; then
                        DO_CLEAN_DEVICE=false
                        echo -e "  ${YELLOW}→ Clean device: выкл${NC}"
                        break
                    fi
                    if is_yes_default_input "$_clean_choice"; then
                        DO_CLEAN_DEVICE=true
                        echo -e "  ${GREEN}→ Clean device: ВКЛ${NC}"
                        break
                    fi
                    echo -e "${RED}  Введите y/yes, n/no или b/back.${NC}"
                done
                _step=7
                ;;

            7)
                local _sf_choice
                while true; do
                    read -rp "$(echo -e "\n${YELLOW}[7]${NC} Синхронизировать выходные данные с SourceForge? [Y/n, b = назад]: ")" _sf_choice
                    if is_back_input "$_sf_choice"; then
                        _step=6
                        continue 2
                    fi
                    if is_no_input "$_sf_choice"; then
                        SYNC_SF=false
                        SF_STOCK_KERNEL_IMG=""
                        SF_OUT_DIR=""
                        echo -e "  ${YELLOW}→ SourceForge sync: выкл${NC}"
                        _step=10
                        continue 2
                    fi
                    if is_yes_default_input "$_sf_choice"; then
                        SYNC_SF=true
                        echo -e "  ${GREEN}→ SourceForge sync: ВКЛ${NC}"
                        _step=8
                        continue 2
                    fi
                    echo -e "${RED}  Введите y/yes, n/no или b/back.${NC}"
                done
                ;;

            8)
                echo -e "\n${YELLOW}[8] Выберите stock boot.img для SourceForge (из pixel-kernels/prebuild-*):${NC}"
                local _pblist
                _pblist=$(find "${KERNEL_BASE_PATH_PIXEL}" -maxdepth 2 -name "boot.img" \
                    -path "*/prebuild*" 2>/dev/null | sort)

                if [ -z "$_pblist" ]; then
                    echo -e "  ${YELLOW}Prebuilt boot.img не найдены. boot_stock.img не будет загружен.${NC}"
                    local _pb_empty
                    read -rp "  Enter = продолжить, b = назад: " _pb_empty
                    if is_back_input "$_pb_empty"; then
                        _step=7
                        continue
                    fi
                    SF_STOCK_KERNEL_IMG=""
                else
                    echo -e "    0) -- Не загружать boot_stock.img --"
                    local _pb_arr=()
                    local _pbidx=1
                    local _default_pbchoice=0
                    while IFS= read -r _pbpath; do
                        [ -z "$_pbpath" ] && continue
                        echo -e "    ${_pbidx}) ${_pbpath}"
                        _pb_arr+=("$_pbpath")
                        if [ "$_pbpath" = "$SF_STOCK_KERNEL_IMG" ]; then
                            _default_pbchoice=$_pbidx
                        fi
                        ((_pbidx++))
                    done <<< "$_pblist"

                    local _pb_choice
                    while true; do
                        read -rp "  Номер [${_default_pbchoice}], b = назад: " _pb_choice
                        if is_back_input "$_pb_choice"; then
                            _step=7
                            continue 2
                        fi
                        _pb_choice="${_pb_choice:-$_default_pbchoice}"
                        if [[ "$_pb_choice" =~ ^[0-9]+$ ]] && \
                           [ "$_pb_choice" -ge 0 ] && [ "$_pb_choice" -lt "$_pbidx" ]; then
                            break
                        fi
                        echo -e "${RED}  Неверный ввод, повторите.${NC}"
                    done

                    if [ "$_pb_choice" -eq 0 ]; then
                        SF_STOCK_KERNEL_IMG=""
                        echo -e "  ${GREEN}→ boot_stock.img: не выбран${NC}"
                    else
                        SF_STOCK_KERNEL_IMG="${_pb_arr[$((_pb_choice-1))]}"
                        echo -e "  ${GREEN}→ boot_stock.img: $SF_STOCK_KERNEL_IMG${NC}"
                    fi
                fi
                _step=9
                ;;

            9)
                local _sfdir_input
                read -rp "$(echo -e "\n${YELLOW}[9]${NC} Подкаталог внутри ${DEVICE_CODE}/$(date +%Y%m%d)/ на SF [Enter = корень, b = назад]: ")" _sfdir_input
                if is_back_input "$_sfdir_input"; then
                    _step=8
                    continue
                fi
                SF_OUT_DIR="${_sfdir_input}"
                if [ -n "$SF_OUT_DIR" ]; then
                    echo -e "  ${GREEN}→ SF subdir: $SF_OUT_DIR${NC}"
                else
                    echo -e "  ${YELLOW}→ SF subdir: (корень даты)${NC}"
                fi
                _step=10
                ;;

            10)
                if [ "$SYNC_SF" = true ]; then
                    SYNC_DRIVE=true
                    echo -e "\n${YELLOW}[10]${NC} GDrive sync будет включен автоматически вместе с SourceForge."
                    echo -e "  ${GREEN}→ GDrive sync: ВКЛ (auto via SF)${NC}"
                    _step=11
                    continue
                fi

                local _gdrive_choice
                while true; do
                    read -rp "$(echo -e "\n${YELLOW}[10]${NC} Синхронизировать выходные данные в ~/GoogleDrive/evox? [Y/n, b = назад]: ")" _gdrive_choice
                    if is_back_input "$_gdrive_choice"; then
                        if [ "$SYNC_SF" = true ]; then
                            _step=9
                        else
                            _step=7
                        fi
                        continue 2
                    fi
                    if is_no_input "$_gdrive_choice"; then
                        SYNC_DRIVE=false
                        echo -e "  ${YELLOW}→ GDrive sync: выкл${NC}"
                        break
                    fi
                    if is_yes_default_input "$_gdrive_choice"; then
                        SYNC_DRIVE=true
                        echo -e "  ${GREEN}→ GDrive sync: ВКЛ${NC}"
                        break
                    fi
                    echo -e "${RED}  Введите y/yes, n/no или b/back.${NC}"
                done
                _step=11
                ;;

            11)
                echo -e "\n${BLUE}══════════════════════════════════════${NC}"
                echo -e "${GREEN}Конфигурация сборки:${NC}"
                echo -e "  Устройство  : $DEVICE_CODE"
                echo -e "  Тип         : $BUILD_TYPE"
                echo -e "  Потоки      : $JOBS"
                echo -e "  Ядро        : ${TARGET_KERNEL_DIR_EXT:-(стоковое)}"
                echo -e "  Release     : $DO_RELEASE"
                echo -e "  Clean device: $DO_CLEAN_DEVICE"
                echo -e "  SF sync     : $SYNC_SF"
                if [ "$SYNC_SF" = true ]; then
                    echo -e "  GDrive sync : true (auto via SF)"
                else
                    echo -e "  GDrive sync : $SYNC_DRIVE"
                fi
                echo -e "  Boot stock  : ${SF_STOCK_KERNEL_IMG:-(нет)}"
                echo -e "  SF subdir   : ${SF_OUT_DIR:-(корень)}"
                echo -e "${BLUE}══════════════════════════════════════${NC}"

                local _confirm_choice
                while true; do
                    read -rp "$(echo -e "${YELLOW}[✓]${NC} Подтвердить конфигурацию? [Y/n, b = назад]: ")" _confirm_choice
                    if is_back_input "$_confirm_choice" || is_no_input "$_confirm_choice"; then
                        _step=10
                        continue 2
                    fi
                    if is_yes_default_input "$_confirm_choice"; then
                        echo ""
                        return 0
                    fi
                    echo -e "${RED}  Введите y/yes, n/no или b/back.${NC}"
                done
                ;;
        esac
    done
}

# ============================================================
# Release: копирование ZIP + образов + JSON в release/
# ============================================================
do_release() {
    local device="$1"
    local src_dir="out/target/product/${device}"
    local date_str
    date_str=$(date +%Y%m%d)
    local kernel_suffix="${TARGET_KERNEL_DIR_EXT:-StockKernel}"
    local release_dir="device/google/release/${date_str}/${device}/${kernel_suffix}"

    echo -e "${BLUE}=== RELEASE: Сохранение билда ===${NC}"
    mkdir -p "$release_dir"

    # 1. Найти последний ZIP
    local zip_path
    zip_path=$(ls -t "$src_dir"/*.zip 2>/dev/null | head -n 1)
    if [ -z "$zip_path" ]; then
        echo -e "${RED}RELEASE: ZIP не найден в $src_dir${NC}"
        return 1
    fi
    local zip_name
    zip_name=$(basename "$zip_path")
    echo -e "  Копирую ZIP: $zip_name"
    cp "$zip_path" "$release_dir/"

    # 2. Скопировать образы (именованные + vbmeta*)
    local images=("dtbo.img" "vendor_boot.img" "vendor_kernel_boot.img" "boot.img" "init_boot.img")
    for img in "${images[@]}"; do
        if [ -f "$src_dir/$img" ]; then
            echo -e "  Копирую: $img"
            cp "$src_dir/$img" "$release_dir/"
        else
            echo -e "  ${YELLOW}[SKIP] $img не найден${NC}"
        fi
    done
    for vb in "$src_dir"/vbmeta*.img; do
        [ -f "$vb" ] || continue
        echo -e "  Копирую: $(basename "$vb")"
        cp "$vb" "$release_dir/"
    done

    # 3. Патчим JSON
    local json_src="$src_dir/${device}.json"
    if [ ! -f "$json_src" ]; then
        echo -e "${YELLOW}RELEASE: JSON не найден: $json_src${NC}"
    else
        local json_dst="$release_dir/${zip_name%.zip}.json"
        echo -e "  Обрабатываю JSON → $(basename "$json_dst")"
        python3 - "$json_src" "$json_dst" <<'PYEOF'
import json, sys
from datetime import datetime

src, dst = sys.argv[1], sys.argv[2]
with open(src, 'r', encoding='utf-8') as f:
    data = json.load(f)

resp = data['response'][0]

# Поля автора и ссылок
resp['maintainer']           = 'LeeGarChat'
resp['oem']                  = 'Google'
resp['buildtype']            = 'user'
resp['forum']                = 'https://t.me/EvoX_LeeGarChat'
resp['paypal']               = 'https://boosty.to/leegar/'
resp['github']               = 'leegarchat'
resp['currently_maintained'] = True

# Аннотация timestamp
ts = resp.get('timestamp', 0)
try:
    dt = datetime.fromtimestamp(int(ts))
    human = dt.strftime('%Y-%m-%d %H:%M:%S')
    # Вставляем аннотационные поля сразу после timestamp
    # (пересобираем словарь, чтобы поля шли по порядку)
    new_resp = {}
    for k, v in resp.items():
        new_resp[k] = v
        if k == 'timestamp':
            new_resp['_timestamp_readable']    = human + '  (локальный часовой пояс)'
            new_resp['_timestamp_convert_cmd'] = "date -d '" + human + "' +%s"
            new_resp['_timestamp_note']        = (
                'Чтобы изменить дату релиза: отредактируй _timestamp_readable, '
                'затем выполни команду из _timestamp_convert_cmd и '
                'запиши результат в поле "timestamp"'
            )
    data['response'][0] = new_resp
except Exception as e:
    resp['_timestamp_error'] = str(e)

with open(dst, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f'OK: {dst}')
PYEOF
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}JSON сохранён: $(basename "$json_dst")${NC}"
        else
            echo -e "  ${RED}Ошибка обработки JSON${NC}"
        fi
    fi

    echo -e "${GREEN}=== RELEASE готов: $release_dir ===${NC}"
    ls -lh "$release_dir/" 2>/dev/null | tail -n +2 | sed 's/^/    /'
}

# ============================================================
# SourceForge Sync: фоновая параллельная загрузка ZIP + образов
# ============================================================
sync_to_sourceforge() {
    local device="$1"
    local src_dir="out/target/product/${device}"
    local date_str
    date_str=$(date +%Y%m%d)
    local sf_base="leegarchat@frs.sourceforge.net:/home/frs/project/evolutionx-unofficial-leegar"

    echo -e "${BLUE}=== SOURCEFORGE SYNC: Подготовка файлов ===${NC}"
    local _sf_display_path="${device}/${date_str}${SF_OUT_DIR:+/${SF_OUT_DIR}}"
    echo -e "  Цель: ${sf_base}/${_sf_display_path}/"

    # Найти последний ZIP
    local zip_path
    zip_path=$(ls -t "${src_dir}"/*.zip 2>/dev/null | head -n 1)
    if [ -z "$zip_path" ]; then
        echo -e "${RED}SF SYNC: ZIP не найден в ${src_dir}${NC}"
        return 1
    fi

    # Staging-директория с нужной структурой.
    # rsync умеет создавать поддиректории при синхронизации дерева,
    # в отличие от SSH-команды mkdir, которую SF запрещает.
    local _stage
    _stage=$(mktemp -d)
    local _stage_root
    if [ -n "$SF_OUT_DIR" ]; then
        _stage_root="${_stage}/${device}/${date_str}/${SF_OUT_DIR}"
    else
        _stage_root="${_stage}/${device}/${date_str}"
    fi
    local _stage_recovery="${_stage_root}/recovery"
    mkdir -p "${_stage_root}" "${_stage_recovery}"

    echo -e "${YELLOW}  Копирование файлов в staging...${NC}"

    # ZIP → корень
    if ! cp --reflink=auto "${zip_path}" "${_stage_root}/"; then
        echo -e "${RED}SF SYNC: Не удалось скопировать ZIP в staging.${NC}"
        rm -rf "$_stage"
        return 1
    fi
    echo -e "  + $(basename "$zip_path")"

    # img-файлы → recovery/
    local _recovery_imgs=("dtbo.img" "vendor_boot.img" "vendor_kernel_boot.img" "boot.img" "init_boot.img")
    for _img in "${_recovery_imgs[@]}"; do
        if [ -f "${src_dir}/${_img}" ]; then
            if ! cp --reflink=auto "${src_dir}/${_img}" "${_stage_recovery}/"; then
                echo -e "${RED}SF SYNC: Не удалось скопировать $_img в staging.${NC}"
                rm -rf "$_stage"
                return 1
            fi
            echo -e "  + ${_img} → recovery/"
        fi
    done

    # vbmeta* → recovery/
    for _vb in "${src_dir}"/vbmeta*.img; do
        [ -f "$_vb" ] || continue
        if ! cp --reflink=auto "$_vb" "${_stage_recovery}/"; then
            echo -e "${RED}SF SYNC: Не удалось скопировать $(basename "$_vb") в staging.${NC}"
            rm -rf "$_stage"
            return 1
        fi
        echo -e "  + $(basename "$_vb") → recovery/"
    done

    # boot_stock.img → recovery/
    if [ -n "$SF_STOCK_KERNEL_IMG" ] && [ -f "$SF_STOCK_KERNEL_IMG" ]; then
        if ! cp --reflink=auto "$SF_STOCK_KERNEL_IMG" "${_stage_recovery}/boot_stock.img"; then
            echo -e "${RED}SF SYNC: Не удалось скопировать boot_stock.img в staging.${NC}"
            rm -rf "$_stage"
            return 1
        fi
        echo -e "  + boot_stock.img → recovery/ (src: $SF_STOCK_KERNEL_IMG)"
    fi

    local _sf_parallel="${SF_UPLOAD_JOBS:-4}"
    if ! [[ "$_sf_parallel" =~ ^[0-9]+$ ]] || [ "$_sf_parallel" -lt 1 ]; then
        _sf_parallel=4
    fi

    local _sf_log_dir="$BAK_ROOT/sf_upload_logs"
    mkdir -p "$_sf_log_dir"
    local _sf_log="$_sf_log_dir/${device}_$(date +%Y%m%d_%H%M%S).log"

    (
        exec >> "$_sf_log" 2>&1
        echo "=== SOURCEFORGE SYNC BACKGROUND START: $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo "Target: ${sf_base}/${_sf_display_path}/"
        echo "Stage : ${_stage}"
        echo "Jobs  : ${_sf_parallel}"

        cd "$_stage" || exit 1

        # --relative создаёт нужные подкаталоги на SourceForge без отдельного ssh mkdir.
        find . -type f -print0 | xargs -0 -r -P "$_sf_parallel" -I {} bash -c '
            rel="${1#./}"
            echo "[SF] Upload: ${rel}"
            rsync -avP --no-perms --omit-dir-times -e ssh --relative "$1" "${2}/"
        ' _ "{}" "$sf_base"
        local _rsync_status=$?

        if [ $_rsync_status -eq 0 ]; then
            echo "=== SOURCEFORGE SYNC BACKGROUND OK: $(date '+%Y-%m-%d %H:%M:%S') ==="
        else
            echo "=== SOURCEFORGE SYNC BACKGROUND FAILED: rsync/xargs code $_rsync_status, $(date '+%Y-%m-%d %H:%M:%S') ==="
        fi

        rm -rf "$_stage"
        exit $_rsync_status
    ) &
    local _sf_pid=$!

    echo -e "${GREEN}=== SOURCEFORGE SYNC: Upload запущен в фоне (PID ${_sf_pid}, jobs: ${_sf_parallel}) ===${NC}"
    echo -e "${YELLOW}    Лог: ${_sf_log}${NC}"
    echo -e "${YELLOW}    Staging сохранён до окончания upload: ${_stage}${NC}"
    return 0
}

# ============================================================
# Google Drive Sync: фоновое параллельное копирование в ~/GoogleDrive/evox
# ============================================================
start_gdrive_stage_copy() {
    local _stage="$1"
    local _display_path="$2"
    local _label="$3"
    local _drive_base="$GDRIVE_ROOT"

    if [ ! -d "$_drive_base" ]; then
        echo -e "${RED}GDrive SYNC: Папка не найдена: $_drive_base${NC}"
        echo -e "${YELLOW}    Подключи Google Drive или задай GDRIVE_ROOT=/path/to/evox.${NC}"
        return 1
    fi

    local _drive_parallel="${GDRIVE_COPY_JOBS:-4}"
    if ! [[ "$_drive_parallel" =~ ^[0-9]+$ ]] || [ "$_drive_parallel" -lt 1 ]; then
        _drive_parallel=4
    fi

    local _gdrive_log_dir="$BAK_ROOT/gdrive_copy_logs"
    mkdir -p "$_gdrive_log_dir"
    local _safe_label
    _safe_label=$(echo "$_label" | tr '/ ' '__' | tr -cd '[:alnum:]_.-')
    local _gdrive_log="$_gdrive_log_dir/${_safe_label}_$(date +%Y%m%d_%H%M%S).log"

    (
        exec >> "$_gdrive_log" 2>&1
        echo "=== GDRIVE SYNC BACKGROUND START: $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo "Target base: ${_drive_base}"
        echo "Payload path: ${_display_path}"
        echo "Stage : ${_stage}"
        echo "Jobs  : ${_drive_parallel}"

        cd "$_stage" || exit 1

        find . -type f -print0 | xargs -0 -r -P "$_drive_parallel" -I {} bash -c '
            rel="${1#./}"
            dest="${2}/${rel}"
            echo "[GDRIVE] Copy: ${rel}"
            mkdir -p "$(dirname "$dest")" || exit 1
            cp -f --reflink=auto "$1" "$dest"
        ' _ "{}" "$_drive_base"
        local _copy_status=$?

        if [ $_copy_status -eq 0 ]; then
            echo "=== GDRIVE SYNC BACKGROUND OK: $(date '+%Y-%m-%d %H:%M:%S') ==="
        else
            echo "=== GDRIVE SYNC BACKGROUND FAILED: copy/xargs code $_copy_status, $(date '+%Y-%m-%d %H:%M:%S') ==="
        fi

        rm -rf "$_stage"
        exit $_copy_status
    ) &
    local _gdrive_pid=$!

    echo -e "${GREEN}=== GDrive SYNC: Копирование запущено в фоне (PID ${_gdrive_pid}, jobs: ${_drive_parallel}) ===${NC}"
    echo -e "${YELLOW}    Цель: ${_drive_base}/${NC}"
    echo -e "${YELLOW}    Пути: ${_display_path}${NC}"
    echo -e "${YELLOW}    Лог: ${_gdrive_log}${NC}"
    echo -e "${YELLOW}    Staging сохранён до окончания copy: ${_stage}${NC}"
    return 0
}

sync_to_gdrive() {
    local device="$1"
    local src_dir="out/target/product/${device}"
    local date_str
    date_str=$(date +%Y%m%d)

    echo -e "${BLUE}=== GDRIVE SYNC: Подготовка файлов ===${NC}"
    local _drive_display_path="${device}/${date_str}${SF_OUT_DIR:+/${SF_OUT_DIR}}"
    echo -e "  Цель: ${GDRIVE_ROOT}/${_drive_display_path}/"

    local zip_path
    zip_path=$(ls -t "${src_dir}"/*.zip 2>/dev/null | head -n 1)
    if [ -z "$zip_path" ]; then
        echo -e "${RED}GDrive SYNC: ZIP не найден в ${src_dir}${NC}"
        return 1
    fi

    local _stage
    _stage=$(mktemp -d)
    local _stage_root
    if [ -n "$SF_OUT_DIR" ]; then
        _stage_root="${_stage}/${device}/${date_str}/${SF_OUT_DIR}"
    else
        _stage_root="${_stage}/${device}/${date_str}"
    fi
    local _stage_recovery="${_stage_root}/recovery"
    mkdir -p "${_stage_root}" "${_stage_recovery}"

    echo -e "${YELLOW}  Копирование файлов в staging...${NC}"

    if ! cp --reflink=auto "${zip_path}" "${_stage_root}/"; then
        echo -e "${RED}GDrive SYNC: Не удалось скопировать ZIP в staging.${NC}"
        rm -rf "$_stage"
        return 1
    fi
    echo -e "  + $(basename "$zip_path")"

    local _recovery_imgs=("dtbo.img" "vendor_boot.img" "vendor_kernel_boot.img" "boot.img" "init_boot.img")
    for _img in "${_recovery_imgs[@]}"; do
        if [ -f "${src_dir}/${_img}" ]; then
            if ! cp --reflink=auto "${src_dir}/${_img}" "${_stage_recovery}/"; then
                echo -e "${RED}GDrive SYNC: Не удалось скопировать $_img в staging.${NC}"
                rm -rf "$_stage"
                return 1
            fi
            echo -e "  + ${_img} → recovery/"
        fi
    done

    for _vb in "${src_dir}"/vbmeta*.img; do
        [ -f "$_vb" ] || continue
        if ! cp --reflink=auto "$_vb" "${_stage_recovery}/"; then
            echo -e "${RED}GDrive SYNC: Не удалось скопировать $(basename "$_vb") в staging.${NC}"
            rm -rf "$_stage"
            return 1
        fi
        echo -e "  + $(basename "$_vb") → recovery/"
    done

    if [ -n "$SF_STOCK_KERNEL_IMG" ] && [ -f "$SF_STOCK_KERNEL_IMG" ]; then
        if ! cp --reflink=auto "$SF_STOCK_KERNEL_IMG" "${_stage_recovery}/boot_stock.img"; then
            echo -e "${RED}GDrive SYNC: Не удалось скопировать boot_stock.img в staging.${NC}"
            rm -rf "$_stage"
            return 1
        fi
        echo -e "  + boot_stock.img → recovery/ (src: $SF_STOCK_KERNEL_IMG)"
    fi

    start_gdrive_stage_copy "$_stage" "$_drive_display_path" "${device}_build"
    local _start_status=$?
    if [ $_start_status -ne 0 ]; then
        rm -rf "$_stage"
    fi
    return $_start_status
}

sync_release_to_gdrive() {
    local requested_date="$1"
    local release_base="device/google/release"

    echo -e "${BLUE}=== GDRIVE RELEASE SYNC: Подготовка existing release файлов ===${NC}"

    if [ ! -d "$release_base" ]; then
        echo -e "${RED}GDrive RELEASE: Папка не найдена: $release_base${NC}"
        return 1
    fi

    local -a _dates=()
    if [ -z "$requested_date" ]; then
        local _latest_date
        _latest_date=$(find "$release_base" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
            | grep -E '^[0-9]{8}$' \
            | sort \
            | tail -n 1)
        if [ -z "$_latest_date" ]; then
            echo -e "${RED}GDrive RELEASE: В $release_base нет date-директорий.${NC}"
            return 1
        fi
        _dates+=("$_latest_date")
    elif [ "${requested_date,,}" = "all" ]; then
        while IFS= read -r _date_dir; do
            _dates+=("$_date_dir")
        done < <(find "$release_base" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
            | grep -E '^[0-9]{8}$' \
            | sort)
    elif [[ "$requested_date" =~ ^[0-9]{8}$ ]]; then
        if [ ! -d "$release_base/$requested_date" ]; then
            echo -e "${RED}GDrive RELEASE: Дата не найдена: $release_base/$requested_date${NC}"
            return 1
        fi
        _dates+=("$requested_date")
    else
        echo -e "${RED}GDrive RELEASE: Укажи дату YYYYMMDD, all или оставь параметр пустым.${NC}"
        return 1
    fi

    if [ "${#_dates[@]}" -eq 0 ]; then
        echo -e "${RED}GDrive RELEASE: Нет date-директорий для синхронизации.${NC}"
        return 1
    fi

    local _stage
    _stage=$(mktemp -d)
    local _release_dirs=0
    local _files=0

    for _date in "${_dates[@]}"; do
        while IFS= read -r _release_dir; do
            [ -d "$_release_dir" ] || continue
            _release_dirs=$((_release_dirs + 1))

            local _rel_path="${_release_dir#$release_base/}"
            local _rel_date _rel_device _rel_subdir
            IFS='/' read -r _rel_date _rel_device _rel_subdir <<< "$_rel_path"
            if [ -z "$_rel_date" ] || [ -z "$_rel_device" ] || [ -z "$_rel_subdir" ]; then
                echo -e "${YELLOW}[SKIP] Неожиданная структура release: $_release_dir${NC}"
                continue
            fi

            local _stage_root="${_stage}/${_rel_device}/${_rel_date}/${_rel_subdir}"
            local _stage_recovery="${_stage_root}/recovery"
            mkdir -p "$_stage_root" "$_stage_recovery"

            for _file in "$_release_dir"/*; do
                [ -f "$_file" ] || continue
                local _name
                _name=$(basename "$_file")
                if [ "$_name" = "boot_stock.img" ]; then
                    echo -e "  ${YELLOW}[SKIP] boot_stock.img: $_release_dir${NC}"
                    continue
                fi

                case "$_name" in
                    *.img)
                        cp --reflink=auto "$_file" "$_stage_recovery/"
                        echo -e "  + ${_rel_device}/${_rel_date}/${_rel_subdir}/recovery/${_name}"
                        ;;
                    *)
                        cp --reflink=auto "$_file" "$_stage_root/"
                        echo -e "  + ${_rel_device}/${_rel_date}/${_rel_subdir}/${_name}"
                        ;;
                esac
                _files=$((_files + 1))
            done
        done < <(find "$release_base/$_date" -mindepth 2 -maxdepth 2 -type d | sort)
    done

    if [ "$_release_dirs" -eq 0 ] || [ "$_files" -eq 0 ]; then
        echo -e "${RED}GDrive RELEASE: Не найдено файлов для синхронизации.${NC}"
        rm -rf "$_stage"
        return 1
    fi

    local _display
    if [ "${requested_date,,}" = "all" ]; then
        _display="all release dates"
    else
        _display="release ${_dates[*]}"
    fi
    start_gdrive_stage_copy "$_stage" "$_display" "release_${requested_date:-latest}"
    local _start_status=$?
    if [ $_start_status -ne 0 ]; then
        rm -rf "$_stage"
    fi
    return $_start_status
}

# ============================================================
# Recovery: восстановление изменений из последнего snapshot
# ============================================================
restore_from_latest_snapshot() {
    echo -e "${BLUE}=== RECOVERY (--rep): Поиск последнего snapshot ===${NC}"

    if [ ! -d "$BAK_ROOT" ]; then
        echo -e "${RED}RECOVERY: Папка '$BAK_ROOT' не найдена.${NC}"
        return 1
    fi

    local latest_snapshot
    latest_snapshot=$(find "$BAK_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
        | grep -E '^[0-9]{8}_[0-9]{6}$' \
        | sort \
        | tail -n 1)

    if [ -z "$latest_snapshot" ]; then
        echo -e "${RED}RECOVERY: Snapshot не найден в '$BAK_ROOT'.${NC}"
        return 1
    fi

    local snapshot_dir="$BAK_ROOT/$latest_snapshot"
    local diff_dir="$snapshot_dir/diff"
    local new_files_dir="$snapshot_dir/new_files_temp"

    if [ ! -d "$diff_dir" ]; then
        echo -e "${RED}RECOVERY: В snapshot отсутствует '$diff_dir'.${NC}"
        return 1
    fi

    echo -e "${YELLOW}--> Snapshot: $snapshot_dir${NC}"
    echo -e "${YELLOW}--> Применение патчей из $diff_dir ...${NC}"

    local total=0
    local ok=0
    local fail=0

    while IFS= read -r patch_path; do
        [ -f "$patch_path" ] || continue
        total=$((total + 1))

        local rel_path
        rel_path="${patch_path#$diff_dir/}"
        rel_path="${rel_path%.patch}"

        if [ ! -f "$rel_path" ]; then
            echo -e "${YELLOW}[SKIP] Файл не найден в дереве: $rel_path${NC}"
            fail=$((fail + 1))
            continue
        fi

        local orig_storage_path
        orig_storage_path=$(backup_storage_path "$rel_path")
        mkdir -p "$(dirname "$ORIG_DIR/$orig_storage_path")"
        cp "$rel_path" "$ORIG_DIR/$orig_storage_path"

        patch -p0 "$rel_path" < "$patch_path" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}OK:${NC} $rel_path"
            ok=$((ok + 1))
        else
            echo -e "${RED}CONFLICT:${NC} $rel_path (проверь .rej/.orig)"
            fail=$((fail + 1))
        fi
    done < <(find "$diff_dir" -type f -name "*.patch" | sort)

    if [ -d "$new_files_dir" ]; then
        echo -e "${YELLOW}--> Восстановление новых файлов из $new_files_dir ...${NC}"
        cp -rf "$new_files_dir/." "./"
    fi

    echo -e "${BLUE}=== RECOVERY: Готово. Всего: $total, успешно: $ok, с ошибками: $fail ===${NC}"

    [ $fail -eq 0 ]
}

# ============================================================
# Выполнение одной сборки (общая логика для CLI и очереди)
# ============================================================
_execute_build() {
    # Использует глобалы: DEVICE_CODE, BUILD_TYPE, JOBS, TARGET_KERNEL_DIR_EXT,
    #                     DO_RELEASE, SYNC_SF, SF_STOCK_KERNEL_IMG, SF_OUT_DIR,
    #                     SYNC_DRIVE, FORCE_ENV, DO_CLEAN, APP_TARGET, VERSION_PART

    [ -z "$BUILD_TYPE" ] && BUILD_TYPE="userdebug"
    local _lunch="lineage_${DEVICE_CODE}-${VERSION_PART}-${BUILD_TYPE}"
    echo -e "${BLUE}=== BUILD PREP: $DEVICE_CODE ($_lunch) ===${NC}"

    # Envsetup
    if [ "$FORCE_ENV" = true ] || [ "$DO_CLEAN" = true ] || ! type -t m > /dev/null; then
        echo -e "${YELLOW}--> source build/envsetup.sh${NC}"
        if [ -f "build/envsetup.sh" ]; then
            source build/envsetup.sh
        else
            echo -e "${RED}Файл build/envsetup.sh не найден!${NC}"
            return 1
        fi
    fi

    # Lunch
    if [ "$FORCE_LUNCH" = true ] || [[ "$TARGET_PRODUCT" != *"$DEVICE_CODE"* ]] \
    || [[ "$TARGET_BUILD_VARIANT" != "$BUILD_TYPE" ]]; then
        echo -e "${YELLOW}--> lunch $_lunch${NC}"
        lunch "$_lunch"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Lunch failed. Пробую стандартный evolution...${NC}"
            lunch "evolution_${DEVICE_CODE}-${BUILD_TYPE}"
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    fi

    # Clean
    if [ "$DO_CLEAN" = true ]; then
        echo -e "${YELLOW}--> m clean${NC}"
        m clean
    fi

    # Build Command
    if [ -n "$APP_TARGET" ]; then
        echo -e "${GREEN}=== BUILDING APP: $APP_TARGET ===${NC}"
        m "$APP_TARGET" $JOBS
        return $?
    fi

    echo -e "${GREEN}=== BUILDING ROM ===${NC}"
    m evolution $JOBS
    local _build_status=$?

    if [ $_build_status -eq 0 ] && [ "$DO_RELEASE" = true ]; then
        do_release "$DEVICE_CODE"
    fi

    if [ $_build_status -eq 0 ] && [ "$SYNC_SF" = true ]; then
        sync_to_sourceforge "$DEVICE_CODE"
    fi

    if [ $_build_status -eq 0 ] && { [ "$SYNC_DRIVE" = true ] || [ "$SYNC_SF" = true ]; }; then
        sync_to_gdrive "$DEVICE_CODE"
    fi

    return $_build_status
}

# ============================================================
# Очередь сборок: набор конфигов → последовательное выполнение
# ============================================================
run_build_queue() {
    local -a _q_dev=() _q_type=() _q_jobs=() _q_kern=()
    local -a _q_rel=() _q_clean=() _q_sf=() _q_sfstock=() _q_sfdir=() _q_drive=()

    # ── Предложить загрузить очередь при старте ──────────────────
    mkdir -p "$QUEUE_SAVE_DIR"
    if ls "$QUEUE_SAVE_DIR"/*.queue > /dev/null 2>&1; then
        local _start_ans
        read -rp "$(echo -e "\n${YELLOW}[?]${NC} Загрузить сохранённую очередь? [Y/n]: ")" _start_ans
        if is_yes_default_input "$_start_ans"; then
            local _lf0_list _lf0_idx=1
            _lf0_list=$(find "$QUEUE_SAVE_DIR" -maxdepth 1 -name "*.queue" | sort)
            local -a _lf0_arr=()
            echo -e "\n${YELLOW}Доступные очереди:${NC}"
            while IFS= read -r _lf0; do
                local _lf0_cnt _lf0_saved
                _lf0_cnt=$(grep -c '|' "$_lf0" 2>/dev/null || echo 0)
                _lf0_saved=$(grep '# Saved:' "$_lf0" 2>/dev/null | sed 's/# Saved: //')
                echo -e "  ${_lf0_idx}) ${BLUE}$(basename "$_lf0" .queue)${NC}  (${_lf0_cnt} сборок, сохранено: ${_lf0_saved})"
                _lf0_arr+=("$_lf0")
                ((_lf0_idx++))
            done <<< "$_lf0_list"
            local _lf0_pick
            read -rp "Номер [0 = отмена]: " _lf0_pick
            if [[ "$_lf0_pick" =~ ^[0-9]+$ ]] && [ "$_lf0_pick" -ge 1 ] && [ "$_lf0_pick" -lt "$_lf0_idx" ]; then
                local _lf0_chosen="${_lf0_arr[$((_lf0_pick-1))]}"
                while IFS='|' read -r _fd _ft _fj _fk _fr _fc _fs _fss _fsd _fgd; do
                    [[ "$_fd" == \#* || -z "$_fd" ]] && continue
                    _q_dev+=("$_fd"); _q_type+=("$_ft"); _q_jobs+=("$_fj"); _q_kern+=("$_fk")
                    _q_rel+=("$_fr"); _q_clean+=("$_fc"); _q_sf+=("$_fs"); _q_sfstock+=("$_fss"); _q_sfdir+=("$_fsd")
                    _q_drive+=("${_fgd:-false}")
                done < "$_lf0_chosen"
                echo -e "${GREEN}Загружено ${#_q_dev[@]} сборок из $(basename "$_lf0_chosen")${NC}"
            fi
        fi
    fi

    while true; do
        # Показываем текущую очередь
        local _n=${#_q_dev[@]}
        if [ "$_n" -gt 0 ]; then
            echo -e "\n${BLUE}╔══════ Очередь сборок: ${_n} шт. ══════╗${NC}"
            for (( _qi=0; _qi<_n; _qi++ )); do
                local _ki="${_q_kern[$_qi]:-стоковое}"
                local _sfd="${_q_sfdir[$_qi]:-(корень)}"
                printf "  ${GREEN}%2d.${NC} %-8s | %-9s | %-5s | %-36s | SF:%-5s | GD:%-5s | dir:%s\n" \
                    $((_qi+1)) "${_q_dev[$_qi]}" "${_q_type[$_qi]}" "${_q_jobs[$_qi]}" \
                    "$_ki" "${_q_sf[$_qi]}" "${_q_drive[$_qi]}" "$_sfd"
            done
            echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"

            local _act
            read -rp "$(echo -e "\n${YELLOW}[→]${NC} [a] Добавить  [s] Сохранить  [l] Загрузить  [Enter] Начать: ")" _act
            case "${_act,,}" in
                s)
                    # ── Сохранение очереди ──────────────────────────────
                    local _sqname
                    read -rp "$(echo -e "${YELLOW}Имя очереди: ${NC}")" _sqname
                    _sqname=$(echo "$_sqname" | tr ' ' '_' | tr -cd '[:alnum:]_.-')
                    [ -z "$_sqname" ] && _sqname="queue_$(date +%Y%m%d_%H%M%S)"
                    local _sqfile="$QUEUE_SAVE_DIR/${_sqname}.queue"
                    {
                        echo "# Queue: $_sqname"
                        echo "# Saved: $(date '+%Y-%m-%d %H:%M:%S')"
                        echo "# Fields: dev|type|jobs|kern|rel|clean|sf|sfstock|sfdir|gdrive"
                        for (( _sqi=0; _sqi<${#_q_dev[@]}; _sqi++ )); do
                            printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
                                "${_q_dev[$_sqi]}" "${_q_type[$_sqi]}" "${_q_jobs[$_sqi]}" \
                                "${_q_kern[$_sqi]}" "${_q_rel[$_sqi]}" "${_q_clean[$_sqi]}" \
                                "${_q_sf[$_sqi]}" "${_q_sfstock[$_sqi]}" "${_q_sfdir[$_sqi]}" "${_q_drive[$_sqi]}"
                        done
                    } > "$_sqfile"
                    echo -e "${GREEN}Очередь сохранена: $_sqfile (${#_q_dev[@]} сборок)${NC}"
                    continue
                    ;;
                l)
                    # ── Загрузка очереди (заменяет текущую) ─────────────
                    local _llf_list
                    _llf_list=$(find "$QUEUE_SAVE_DIR" -maxdepth 1 -name "*.queue" 2>/dev/null | sort)
                    if [ -z "$_llf_list" ]; then
                        echo -e "${RED}Нет сохранённых очередей в $QUEUE_SAVE_DIR.${NC}"
                        continue
                    fi
                    local -a _llf_arr=()
                    local _llf_idx=1
                    echo -e "\n${YELLOW}Доступные очереди:${NC}"
                    while IFS= read -r _llf; do
                        local _llf_cnt _llf_saved
                        _llf_cnt=$(grep -c '|' "$_llf" 2>/dev/null || echo 0)
                        _llf_saved=$(grep '# Saved:' "$_llf" 2>/dev/null | sed 's/# Saved: //')
                        echo -e "  ${_llf_idx}) ${BLUE}$(basename "$_llf" .queue)${NC}  (${_llf_cnt} сборок, ${_llf_saved})"
                        _llf_arr+=("$_llf")
                        ((_llf_idx++))
                    done <<< "$_llf_list"
                    local _llf_pick
                    read -rp "Номер [0 = отмена]: " _llf_pick
                    if [[ "$_llf_pick" =~ ^[0-9]+$ ]] && [ "$_llf_pick" -ge 1 ] && [ "$_llf_pick" -lt "$_llf_idx" ]; then
                        local _ll_chosen="${_llf_arr[$((_llf_pick-1))]}"
                        _q_dev=() _q_type=() _q_jobs=() _q_kern=()
                        _q_rel=() _q_clean=() _q_sf=() _q_sfstock=() _q_sfdir=() _q_drive=()
                        while IFS='|' read -r _fd _ft _fj _fk _fr _fc _fs _fss _fsd _fgd; do
                            [[ "$_fd" == \#* || -z "$_fd" ]] && continue
                            _q_dev+=("$_fd"); _q_type+=("$_ft"); _q_jobs+=("$_fj"); _q_kern+=("$_fk")
                            _q_rel+=("$_fr"); _q_clean+=("$_fc"); _q_sf+=("$_fs"); _q_sfstock+=("$_fss"); _q_sfdir+=("$_fsd")
                            _q_drive+=("${_fgd:-false}")
                        done < "$_ll_chosen"
                        echo -e "${GREEN}Загружено ${#_q_dev[@]} сборок из $(basename "$_ll_chosen")${NC}"
                    fi
                    continue
                    ;;
                a)
                    # fall through to interactive_build_menu
                    ;;
                *)
                    break
                    ;;
            esac
        fi

        # Сброс переменных конфига перед вводом нового
        DEVICE_CODE="" BUILD_TYPE="" JOBS=""
        export TARGET_KERNEL_DIR_EXT=""
        DO_RELEASE=false DO_CLEAN_DEVICE=false
        SYNC_SF=false SYNC_DRIVE=false SF_STOCK_KERNEL_IMG="" SF_OUT_DIR=""

        interactive_build_menu || return 1

        _q_dev+=("$DEVICE_CODE")
        _q_type+=("$BUILD_TYPE")
        _q_jobs+=("$JOBS")
        _q_kern+=("$TARGET_KERNEL_DIR_EXT")
        _q_rel+=("$DO_RELEASE")
        _q_clean+=("$DO_CLEAN_DEVICE")
        _q_sf+=("$SYNC_SF")
        _q_sfstock+=("$SF_STOCK_KERNEL_IMG")
        _q_sfdir+=("$SF_OUT_DIR")
        _q_drive+=("$SYNC_DRIVE")
    done

    # Выполнение очереди
    local _total=${#_q_dev[@]}
    if [ "$_total" -eq 0 ]; then
        echo -e "${YELLOW}Очередь пуста. Ничего не запускается.${NC}"
        return 0
    fi
    local _pad
    printf -v _pad "%-38s" "Запуск очереди: ${_total} сборок(и/а)"
    echo -e "\n${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e   "${BLUE}║  ${_pad}║${NC}"
    echo -e   "${BLUE}╚══════════════════════════════════════╝${NC}"

    local _q_failed=0
    for (( _qi=0; _qi<_total; _qi++ )); do
        local _kern_label="${_q_kern[$_qi]:+| ${_q_kern[$_qi]}}"
        echo -e "\n${BLUE}═══ Сборка $((_qi+1))/${_total}: ${_q_dev[$_qi]} [${_q_type[$_qi]}] ${_kern_label} ═══${NC}"

        DEVICE_CODE="${_q_dev[$_qi]}"
        BUILD_TYPE="${_q_type[$_qi]}"
        JOBS="${_q_jobs[$_qi]}"
        export TARGET_KERNEL_DIR_EXT="${_q_kern[$_qi]}"
        DO_RELEASE="${_q_rel[$_qi]}"
        DO_CLEAN_DEVICE="${_q_clean[$_qi]}"
        SYNC_SF="${_q_sf[$_qi]}"
        SF_STOCK_KERNEL_IMG="${_q_sfstock[$_qi]}"
        SF_OUT_DIR="${_q_sfdir[$_qi]}"
        SYNC_DRIVE="${_q_drive[$_qi]}"

        if [ "$DO_CLEAN_DEVICE" = true ]; then
            echo -e "${YELLOW}--> Очистка out/target/product/$DEVICE_CODE ...${NC}"
            rm -rf "out/target/product/$DEVICE_CODE"
        fi

        _execute_build
        local _item_st=$?
        if [ $_item_st -ne 0 ]; then
            _q_failed=$((_q_failed + 1))
            echo -e "${RED}✗ Сборка $((_qi+1)) FAILED (код $_item_st). Продолжаю очередь...${NC}"
        else
            echo -e "${GREEN}✓ Сборка $((_qi+1)) завершена успешно.${NC}"
        fi
    done

    echo -e "\n${BLUE}═══ Очередь завершена: ${_total} сборок, ${_q_failed} ошибок ═══${NC}"
    [ $_q_failed -eq 0 ]
}

main() {
    # Сброс переменных при повторном запуске в той же сессии
    DO_SYNC=false
    FORCE_SYNC_ONLY=false
    DO_BUILD=false
    DO_CLEAN=false
    DO_SETUP_ENV=false
    DO_KILL=false
    DO_REP=false
    FORCE_ENV=false
    FORCE_LUNCH=false
    DO_RELEASE=false
    APP_TARGET=""
    SYNC_DRIVE=false
    SYNC_DRIVE_RELEASE=false
    DRIVE_RELEASE_DATE=""
    SYNC_SF=false
    SF_STOCK_KERNEL_IMG=""
    SF_OUT_DIR=""
    export RELEASE_PIXEL_2025_ENABLED="true"
    # Парсинг аргументов
    export TARGET_KERNEL_IMAGES_EXT="0"
    while [[ $# -gt 0 ]]; do
      case $1 in
        --setup-env) DO_SETUP_ENV=true; shift ;;
        --kill)      DO_KILL=true; shift ;;
        --rep)       DO_REP=true; shift ;;
        --sync)      DO_SYNC=true; shift ;;
        --forcesync) DO_SYNC=true; FORCE_SYNC_ONLY=true; shift ;;
        --build)     DO_BUILD=true; shift ;;
        --clean)     DO_CLEAN=true; shift ;;
        --env)       FORCE_ENV=true; shift ;;
        --lunch)     FORCE_LUNCH=true; shift ;;
        --app)
             if [ -n "$2" ] && [[ "$2" != --* ]]; then
                 APP_TARGET="$2"
                 shift 2
             else
                 echo -e "${RED}Ошибка: --app требует имя приложения (напр. Settings)${NC}"
                 safe_exit 1
             fi
             ;;
        --version)
             if [ -n "$2" ] && [[ "$2" != --* ]]; then
                 VERSION_PART="$2"
                 shift 2
             else
                 echo -e "${RED}Ошибка: --version требует параметр (напр. bp4a)${NC}"
                 safe_exit 1
             fi
             ;;
        -j)          JOBS="-j$2"; shift 2 ;;
        --clean-device)
            DO_CLEAN_DEVICE=true
            shift
            ;;
        --sync-drive)
            SYNC_DRIVE=true
            shift
            ;;
        --sync-drive-release)
            SYNC_DRIVE_RELEASE=true
            if [ -n "$2" ] && [[ "$2" != --* ]] && { [[ "$2" =~ ^[0-9]{8}$ ]] || [ "${2,,}" = "all" ]; }; then
                DRIVE_RELEASE_DATE="$2"
                shift 2
            else
                shift
            fi
            ;;
        --sync-sf)
            SYNC_SF=true
            SYNC_DRIVE=true
            shift
            ;;
        --sf-stock-kernel)
            if [ -n "$2" ] && [[ "$2" != --* ]]; then
                if [ -f "$2" ]; then
                    SF_STOCK_KERNEL_IMG="$2"
                else
                    echo -e "${RED}Ошибка: --sf-stock-kernel: файл '$2' не найден${NC}"
                    safe_exit 1
                fi
                shift 2
            else
                echo -e "${RED}Ошибка: --sf-stock-kernel требует путь к boot.img${NC}"
                safe_exit 1
            fi
            ;;
        --out-sf-dir)
            if [ -n "$2" ] && [[ "$2" != --* ]]; then
                SF_OUT_DIR="$2"
                shift 2
            else
                echo -e "${RED}Ошибка: --out-sf-dir требует имя подкаталога${NC}"
                safe_exit 1
            fi
            ;;
        --release)
            DO_RELEASE=true
            shift
            ;;
        --prebuild-kernel) export TARGET_KERNEL_IMAGES_EXT=1; shift ;;
        --kernel)
            # 1. Проверка, передан ли параметр
            if [ -z "$2" ]; then
                echo "❌ Ошибка: Для параметра '--kernel' требуется указать имя каталога."
                echo "   Использование: --kernel <ИмяКаталога>"
                list_available_kernels $KERNEL_BASE_PATH_PIXEL
                return 1 
            fi

            KERNEL_EXTENSION="$2"
            KERNEL_FULL_PATH="$KERNEL_BASE_PATH_PIXEL/$KERNEL_EXTENSION"

            # 2. Проверка, существует ли каталог
            if [ -d "$KERNEL_FULL_PATH" ]; then
                export TARGET_KERNEL_DIR_EXT="$KERNEL_EXTENSION"
                echo "✅ Установлен TARGET_KERNEL_DIR_EXT: $TARGET_KERNEL_DIR_EXT"
                shift 2
            else
                echo "❌ Ошибка: Каталог ядра '$KERNEL_FULL_PATH' не найден."
                echo "   Проверьте правильность имени или используйте '--ls-kernel' для списка."
                return 1 
            fi
            ;;

        --ls-kernel)
            list_available_kernels $KERNEL_BASE_PATH_PIXEL
            shift 1
            ;;
        --help)      show_help; safe_exit 0 ; return 0;;
        *)
          if [[ "$DO_BUILD" == "true" && -z "$DEVICE_CODE" ]]; then
            DEVICE_CODE="$1"
          elif [[ "$DO_BUILD" == "true" && -z "$BUILD_TYPE" ]]; then
            BUILD_TYPE="$1"
          else
            echo -e "${RED}Неизвестный параметр: $1${NC}"
            safe_exit 1
          fi
          shift
          ;;
      esac
    done

    # Восстановление изменений из последнего snapshot
    if [ "$DO_REP" = true ]; then
        restore_from_latest_snapshot
        if [ $? -ne 0 ]; then
            safe_exit 1
        fi
        if [ "$DO_SYNC" = false ] && [ "$DO_BUILD" = false ] && [ "$DO_SETUP_ENV" = false ] && [ "$DO_KILL" = false ]; then
            safe_exit 0
        fi
    fi

    if [ "$DO_CLEAN_DEVICE" = true ]; then
        if [ -n "$DEVICE_CODE" ]; then
            echo -e "${YELLOW}--> Очистка out/target/product/$DEVICE_CODE ...${NC}"
            rm -rf "out/target/product/$DEVICE_CODE"
        else
             echo -e "${RED}Ошибка: --clean-device требует указания устройства (codename)!${NC}"
             safe_exit 1
        fi
    fi
    # 0. KILL BUILD
    if [ "$DO_KILL" = true ]; then
        kill_build
        if [ "$DO_SYNC" = false ] && [ "$DO_BUILD" = false ]; then
            safe_exit 0
        fi
    fi

    # 1. SETUP ENV
    if [ "$DO_SETUP_ENV" = true ]; then
        run_env_setup
        if [ $? -ne 0 ]; then
            echo -e "${RED}Ошибка настройки окружения.${NC}"
            safe_exit 1
        fi
        if [ "$DO_SYNC" = false ] && [ "$DO_BUILD" = false ]; then
            safe_exit 0
        fi
    fi

    # 2. SYNC
    if [ "$DO_SYNC" = true ]; then
        echo -e "${BLUE}=== SYNC: Start ===${NC}"

        # --- FORCESYNC ---
        if [ "$FORCE_SYNC_ONLY" = true ]; then
             echo -e "${YELLOW}!!! FORCE SYNC MODE !!!${NC}"
             echo -e "Пропуск создания патчей. Только repo sync."
             repo sync -c --force-sync --no-clone-bundle --no-tags $JOBS
             if [ $? -ne 0 ]; then
                echo -e "${RED}Repo sync failed.${NC}"
                safe_exit 1
             fi
        
        # --- SMART SYNC ---
        else
             if [ ! -d "$ORIG_DIR" ]; then
                echo -e "${RED}Ошибка: Папка $ORIG_DIR не найдена!${NC}"
                safe_exit 1
             fi

             local CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
             SNAPSHOT_DIR="$BAK_ROOT/$CURRENT_DATE"
             mkdir -p "$SNAPSHOT_DIR/diff" "$SNAPSHOT_DIR/copy"
             
             # === NEW FILES BACKUP (Custom Feature) ===
             local NEW_FILES_BACKUP_DIR="$SNAPSHOT_DIR/new_files_temp"
             if [ -f "$NEW_FILES_LIST" ]; then
                echo -e "${YELLOW}--> Резервное копирование новых файлов (из $NEW_FILES_LIST)...${NC}"
                mkdir -p "$NEW_FILES_BACKUP_DIR"
                
                # Читаем файл построчно, убираем пустые строки и пробелы
                grep -v '^[[:space:]]*$' "$NEW_FILES_LIST" | while read -r raw_line; do
                    # Конвертация Windows путей (\) в Linux (/) и удаление пробелов
                    local file_path=$(echo "$raw_line" | tr '\\' '/' | xargs)
                    
                    if [ -e "$file_path" ]; then
                        # Определяем целевую папку в бэкапе, сохраняя структуру
                        local dest_dir="$NEW_FILES_BACKUP_DIR/$(dirname "$file_path")"
                        mkdir -p "$dest_dir"
                        
                        # Перемещаем файл/папку
                        mv "$file_path" "$dest_dir/"
                        echo "Saved & Moved: $file_path"
                    else
                        echo -e "${YELLOW}[SKIP] Файл не найден для бэкапа: $file_path${NC}"
                    fi
                done
             fi
             # ==========================================

             echo -e "${YELLOW}--> Анализ файлов и сброс изменений (git checkout)...${NC}"
             
             local FILES
             FILES=$(find "$ORIG_DIR" -type f | sed "s|$ORIG_DIR/||" | while IFS= read -r stored_path; do
                 printf '%s\n' "$(backup_tree_path "$stored_path")"
             done)

             for REL_PATH in $FILES; do
                 local REAL_PATH_IN_TREE="$REL_PATH"
                 local ORIG_STORAGE_PATH
                 ORIG_STORAGE_PATH=$(backup_storage_path "$REL_PATH")
                 local FULL_ORIG_PATH="$ORIG_DIR/$ORIG_STORAGE_PATH"
                 
                 if [ -f "$REAL_PATH_IN_TREE" ]; then
                     # Бекап
                     local SNAPSHOT_COPY_PATH="$SNAPSHOT_DIR/copy/$ORIG_STORAGE_PATH"
                     mkdir -p "$(dirname "$SNAPSHOT_COPY_PATH")"
                     cp "$REAL_PATH_IN_TREE" "$SNAPSHOT_COPY_PATH"
                     
                     # Diff
                     mkdir -p "$(dirname "$SNAPSHOT_DIR/diff/$REL_PATH")"
                     diff -u "$FULL_ORIG_PATH" "$REAL_PATH_IN_TREE" > "$SNAPSHOT_DIR/diff/$REL_PATH.patch"
                     
                     if [ ! -s "$SNAPSHOT_DIR/diff/$REL_PATH.patch" ]; then
                        rm "$SNAPSHOT_DIR/diff/$REL_PATH.patch"
                     else
                        echo -e "Patch created: $REL_PATH"
                     fi

                     # Revert через git checkout
                     local FILE_DIR=$(dirname "$REAL_PATH_IN_TREE")
                     local FILE_NAME=$(basename "$REAL_PATH_IN_TREE")
                     
                     if pushd "$FILE_DIR" > /dev/null; then
                         git checkout HEAD -- "$FILE_NAME" 2>/dev/null
                         if [ $? -ne 0 ]; then
                             echo -e "${RED}Checkout failed for $REL_PATH. Fallback to cp.${NC}"
                             cp "$FULL_ORIG_PATH" "$REAL_PATH_IN_TREE"
                         fi
                         popd > /dev/null
                     fi
                 fi
             done

             echo -e "${YELLOW}--> Repo Sync $JOBS ...${NC}"
             repo sync -c --force-sync --no-clone-bundle --no-tags $JOBS
             if [ $? -ne 0 ]; then
                 echo -e "${RED}Sync failed. Changes saved in $SNAPSHOT_DIR${NC}"
                 # Пытаемся вернуть New Files даже при ошибке, чтобы не потерять их
                 if [ -d "$NEW_FILES_BACKUP_DIR" ]; then
                     echo -e "${YELLOW}Emergency restore of new files...${NC}"
                     cp -rf "$NEW_FILES_BACKUP_DIR/." "./"
                 fi
                 safe_exit 1
             fi

             echo -e "${YELLOW}--> Применение патчей...${NC}"
             for REL_PATH in $FILES; do
                 local REAL_PATH_IN_TREE="$REL_PATH"
                 local ORIG_STORAGE_PATH
                 ORIG_STORAGE_PATH=$(backup_storage_path "$REL_PATH")
                 local FULL_ORIG_PATH="$ORIG_DIR/$ORIG_STORAGE_PATH"
                 local PATCH_PATH="$SNAPSHOT_DIR/diff/$REL_PATH.patch"

                 if [ -f "$REAL_PATH_IN_TREE" ]; then
                     cp "$REAL_PATH_IN_TREE" "$FULL_ORIG_PATH"
                     
                     if [ -f "$PATCH_PATH" ]; then
                         echo -e "Patching $REL_PATH ..."
                         patch -p0 "$REAL_PATH_IN_TREE" < "$PATCH_PATH"
                         if [ $? -ne 0 ]; then
                             echo -e "${RED}CONFLICT: $REL_PATH${NC} (Check .rej)"
                         else
                             echo -e "${GREEN}OK: $REL_PATH${NC}"
                         fi
                     fi
                 fi
             done

             # === NEW FILES RESTORE (Custom Feature) ===
             if [ -d "$NEW_FILES_BACKUP_DIR" ]; then
                 echo -e "${YELLOW}--> Восстановление новых файлов...${NC}"
                 # Копируем содержимое бэкапа обратно в корень, перезаписывая, если что-то появилось
                 cp -rf "$NEW_FILES_BACKUP_DIR/." "./"
                 
                 # Удаляем временную папку, файлы остаются в SNAPSHOT_DIR/new_files_temp, 
                 # если вдруг захочется посмотреть историю, но здесь мы просто чистим переменную или папку
                 # В данной логике: файлы уже в безопасности внутри $SNAPSHOT_DIR, так что копию можно оставить там.
                 # Но саму папку temp внутри снепшота можно не удалять, пусть останется как история.
                 
                 echo -e "${GREEN}New files restored successfully.${NC}"
             fi
             # ==========================================
        fi
        echo -e "${BLUE}=== SYNC: Done ===${NC}"
    fi

    # 2.5. GDrive existing release sync
    if [ "$SYNC_DRIVE_RELEASE" = true ]; then
        sync_release_to_gdrive "$DRIVE_RELEASE_DATE"
        if [ $? -ne 0 ]; then
            safe_exit 1
        fi
        if [ "$DO_SYNC" = false ] && [ "$DO_BUILD" = false ] && [ "$DO_SETUP_ENV" = false ] && [ "$DO_KILL" = false ]; then
            safe_exit 0
        fi
    fi

    # 3. BUILD
    if [ "$DO_BUILD" = true ]; then

        if [ -n "$APP_TARGET" ] && [ -z "$DEVICE_CODE" ]; then
            echo -e "${RED}Для сборки приложения укажите устройство!${NC}"
            safe_exit 1
        fi

        if [ -z "$DEVICE_CODE" ]; then
            # Интерактивный режим → очередь сборок
            run_build_queue || safe_exit 1
        else
            # Неинтерактивный режим (параметры из CLI) → одиночная сборка
            # DO_CLEAN_DEVICE уже обработан выше (перед KILL/SETUP блоками)
            _execute_build || safe_exit 1
        fi

    fi
}

# Запуск
main "$@"