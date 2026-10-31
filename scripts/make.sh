#!/usr/bin/env bash
# ============================================================
# 1. Цветовые палитры и оформление TUI
# ============================================================
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_DIM="\033[2m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_BLUE="\033[1;34m"
CLR_MAGENTA="\033[1;35m"
CLR_CYAN="\033[1;36m"
CLR_WHITE="\033[1;37m"

safe_exit() {
    local code="${1:-1}"
    # Если скрипт вызван через source — ставим глобальный флаг и прерываем цикл
    # return на верхнем уровне (вне функции) корректно выходит из sourced-скрипта
    SAFE_EXIT_CODE="$code"
    SAFE_EXIT_REQUESTED=true
}

cleanup_on_interrupt() {
    echo -e "\n${CLR_RED}⚠️ Сборка прервана пользователем (SIGINT / Ctrl+C)${CLR_RESET}"
    if [ -n "$ACTIVE_BUILD_PID" ] && kill -0 "$ACTIVE_BUILD_PID" 2>/dev/null; then
        kill -TERM "$ACTIVE_BUILD_PID" 2>/dev/null || kill -KILL "$ACTIVE_BUILD_PID" 2>/dev/null
    fi
    pkill -P $$ 2>/dev/null || true
    trap - SIGINT SIGTERM
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 130; else exit 130; fi
}

trap cleanup_on_interrupt SIGINT SIGTERM

# ============================================================
# 2. Глобальные конфигурационные переменные по умолчанию
# ============================================================
DO_BUILD=false
APP_TARGET=""
VERSION_PART="cp2a"
FORCE_ENV=false
FORCE_LUNCH=false
JOBS="-j$(nproc 2>/dev/null || echo 8)"
KERNEL_DIR=""
BUILD_TYPE="userdebug"
DEVICE_CODE=""
DO_RELEASE=false
CUSTOM_RELEASE_PATH=""
MODIFY_JSON=false
CLEAN_DEVICE=false
CLEAN_OUT=false
LS_KERNEL_FLAG=false
CUSTOM_LS_PATH=""

ACTIVE_BUILD_PID=""

SAFE_EXIT_REQUESTED=false
SAFE_EXIT_CODE=0

DEFAULT_KERNEL_BASE="device/google/pixel-kernels"
DEFAULT_RELEASE_BASE="device/google/release"

# ============================================================
# 3. Валидация и отображение ядер (--ls-kernel / -s)
# ============================================================
inspect_kernel_dir() {
    local kdir="$1"
    [ -d "$kdir" ] || return 1
    local name
    name=$(basename "$kdir")
    [[ "$name" == .* || "$name" == "anykernels" ]] && return 1

    local has_ko=false has_boot=false has_dtb=false has_dtbo=false has_image=false has_load=false
    local has_vendor_boot=false

    [ -n "$(find "$kdir" -maxdepth 3 -type f -name "*.ko" -print -quit 2>/dev/null)" ] && has_ko=true
    [ -f "$kdir/boot.img" ] && has_boot=true
    { [ -f "$kdir/dtb.img" ] || [ -n "$(find "$kdir" -maxdepth 3 -type f \( -name "*.dtb" -o -name "dtb" \) -print -quit 2>/dev/null)" ]; } && has_dtb=true
    [ -f "$kdir/dtbo.img" ] && has_dtbo=true
    [ -n "$(find "$kdir" -maxdepth 3 -type f \( -name "Image" -o -name "Image.gz" -o -name "Image.lz4" \) -print -quit 2>/dev/null)" ] && has_image=true
    [ -n "$(find "$kdir" -maxdepth 3 -type f \( -name "*.load" -o -name "*.blocklist" \) -print -quit 2>/dev/null)" ] && has_load=true

    # Строгая проверка: все базовые компоненты ядра должны присутствовать
    if [ "$has_ko" = true ] && [ "$has_boot" = true ] && [ "$has_dtb" = true ] && \
       [ "$has_dtbo" = true ] && [ "$has_image" = true ] && [ "$has_load" = true ]; then
        [ -f "$kdir/vendor_boot.img" ] && has_vendor_boot=true
        echo "$name|$has_vendor_boot"
        return 0
    fi
    return 1
}

list_kernels() {
    local target_path="${1:-$DEFAULT_KERNEL_BASE}"
    echo -e "${CLR_CYAN}╭──────────────────────────────────────────────────────────────────────────╮${CLR_RESET}"
    echo -e "${CLR_CYAN}│ 📦 Проверка и список доступных валидных ядер                            │${CLR_RESET}"
    echo -e "${CLR_CYAN}│ ${CLR_WHITE}Путь: $target_path${CLR_CYAN}${CLR_RESET}"
    echo -e "${CLR_CYAN}╰──────────────────────────────────────────────────────────────────────────╯${CLR_RESET}"

    if [ ! -d "$target_path" ]; then
        echo -e "${CLR_RED}❌ Ошибка: Директория '$target_path' не существует!${CLR_RESET}"
        return 1
    fi

    local valid_found=0
    printf "${CLR_MAGENTA}%-5s %-45s %-18s${CLR_RESET}\n" "№" "Имя директории ядра" "vendor_boot.img"
    echo -e "${CLR_DIM}──────────────────────────────────────────────────────────────────────────${CLR_RESET}"

    local idx=1
    for item in "$target_path"/*; do
        [ -d "$item" ] || continue
        local res
        res=$(inspect_kernel_dir "$item")
        if [ -n "$res" ]; then
            IFS='|' read -r kname vboot <<< "$res"
            local vboot_str="${CLR_DIM}-${CLR_RESET}"
            [ "$vboot" = "true" ] && vboot_str="${CLR_GREEN}✓ Есть${CLR_RESET}"
            printf "${CLR_CYAN}%-5d${CLR_RESET} ${CLR_WHITE}%-45s${CLR_RESET} %-18b\n" "$idx" "$kname" "$vboot_str"
            valid_found=$((idx++))
        fi
    done

    if [ $valid_found -eq 0 ]; then
        echo -e "${CLR_YELLOW}Готовые валидные директории ядер не найдены.${CLR_RESET}"
    fi
    echo ""
}

# ============================================================
# 4. Разбор аргументов командной строки
# ============================================================
show_help() {
    echo -e "${CLR_CYAN}${CLR_BOLD}Android ROM Build Engine (make.sh)${CLR_RESET}"
    echo -e "Использование: ${CLR_GREEN}source ./make.sh -b -d <device> [ОПЦИИ]${CLR_RESET}\n"
    echo -e "${CLR_YELLOW}Параметры компиляции:${CLR_RESET}"
    echo -e "  -b, --build             Запустить компиляцию целевого объекта."
    echo -e "  -d, --device <codename> Кодовое имя устройства (например: shiba, husky)."
    echo -e "  -a, --app <name>        Собрать конкретный модуль/приложение (например: Settings)."
    echo -e "  -v, --version <ver>     Версия платформы для lunch (по умолчанию: cp2a)."
    echo -e "  -t, --type <type>       Тип сборки: user, userdebug (по умолчанию), eng."
    echo -e "  -j, --jobs <num>        Количество параллельных потоков (например: -j16 или -j 16)."
    echo -e "  -k, --kernel <dir>      Кастомное ядро из device/google/pixel-kernels/."
    echo -e "  -s, --ls-kernel [path]  Вывести список валидных ядер."
    echo -e "  -e, --env               Принудительно перезапустить 'source build/envsetup.sh'."
    echo -e "  -l, --lunch             Принудительно перезапустить 'lunch'."
    echo -e "  -r, --release [path]    Экспортировать готовые артефакты в релизную папку."
    echo -e "  -J, --json              Сформировать и модифицировать OTA JSON при релизе."
    echo -e "  -c, --clean-device      Удалить out/target/product/<device> перед сборкой."
    echo -e "  -C, --clean-out         Снести out/ целиком перед сборкой."
    echo -e "  -h, --help              Показать эту справку."
}

while [[ $# -gt 0 ]] && [ "$SAFE_EXIT_REQUESTED" = false ]; do
    case "$1" in
        -b|--build) DO_BUILD=true; shift ;;
        -a|--app)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                APP_TARGET="$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -a/--app требует имя целевого модуля${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -v|--version)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                VERSION_PART="$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -v/--version требует параметр (например: cp2a)${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -e|--env) FORCE_ENV=true; shift ;;
        -l|--lunch) FORCE_LUNCH=true; shift ;;
        -j|--jobs)
            if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                JOBS="-j$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -j/--jobs требует числовой параметр${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -j[0-9]*) JOBS="$1"; shift ;;
        -k|--kernel)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                KERNEL_DIR="$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -k/--kernel требует указания папки ядра${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -s|--ls-kernel)
            LS_KERNEL_FLAG=true
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                CUSTOM_LS_PATH="$2"; shift 2
            else
                shift
            fi
            ;;
        -t|--type)
            if [ -n "$2" ] && [[ "$2" =~ ^(user|userdebug|eng)$ ]]; then
                BUILD_TYPE="$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -t/--type принимает значения: user, userdebug, eng${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -d|--device)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                DEVICE_CODE="$2"; shift 2
            else
                echo -e "${CLR_RED}❌ Ошибка: -d/--device требует указания кодового имени устройства${CLR_RESET}"; safe_exit 1
            fi
            ;;
        -r|--release)
            DO_RELEASE=true
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                CUSTOM_RELEASE_PATH="$2"; shift 2
            else
                shift
            fi
            ;;
        -J|--json) MODIFY_JSON=true; shift ;;
        -c|--clean-device) CLEAN_DEVICE=true; shift ;;
        -C|--clean-out) CLEAN_OUT=true; shift ;;
        -h|--help) show_help; safe_exit 0 ;;
        *)
            echo -e "${CLR_RED}❌ Неизвестный параметр: $1${CLR_RESET}"
            show_help
            safe_exit 1
            ;;
    esac
done

# Если safe_exit был вызван из while-loop (например --help), выходим сразу
if [ "$SAFE_EXIT_REQUESTED" = true ]; then
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        return "$SAFE_EXIT_CODE"
    else
        exit "$SAFE_EXIT_CODE"
    fi
fi

if [ "$LS_KERNEL_FLAG" = true ]; then
    list_kernels "${CUSTOM_LS_PATH:-$DEFAULT_KERNEL_BASE}"
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 0; else exit 0; fi
fi

if [ "$DO_BUILD" = false ]; then
    echo -e "${CLR_YELLOW}Предупреждение: Флаг --build не передан. Используйте --help для справки.${CLR_RESET}"
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 0; else exit 0; fi
fi

if [ -z "$DEVICE_CODE" ]; then
    echo -e "${CLR_RED}❌ Ошибка: Не указано целевое устройство (--device / -d)!${CLR_RESET}"
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 1; else exit 1; fi
fi

# ============================================================
# 5. Инициализация окружения (envsetup & lunch)
# ============================================================
if [ -n "$KERNEL_DIR" ]; then
    export TARGET_KERNEL_DIR_EXT="$KERNEL_DIR"
    echo -e "${CLR_GREEN}✓ Установлено кастомное ядро:${CLR_RESET} $KERNEL_DIR"
fi

PRIMARY_LUNCH="lineage_${DEVICE_CODE}-${VERSION_PART}-${BUILD_TYPE}"
FALLBACK_LUNCH_1="evolution_${DEVICE_CODE}-${VERSION_PART}-${BUILD_TYPE}"
FALLBACK_LUNCH_2="evolution_${DEVICE_CODE}-${BUILD_TYPE}"

if [ "$FORCE_ENV" = true ] || ! type -t m >/dev/null 2>&1; then
    echo -e "${CLR_YELLOW}--> source build/envsetup.sh${CLR_RESET}"
    if [ -f "build/envsetup.sh" ]; then
        source build/envsetup.sh
    else
        echo -e "${CLR_RED}❌ Файл build/envsetup.sh не найден!${CLR_RESET}"
        if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 1; else exit 1; fi
    fi
fi

if [ "$FORCE_LUNCH" = true ] || [[ "${TARGET_PRODUCT:-}" != *"$DEVICE_CODE"* ]] || [[ "${TARGET_BUILD_VARIANT:-}" != "$BUILD_TYPE" ]]; then
    echo -e "${CLR_YELLOW}--> Подготовка конфигурации (lunch $PRIMARY_LUNCH)...${CLR_RESET}"
    if ! lunch "$PRIMARY_LUNCH" 2>/dev/null; then
        echo -e "${CLR_YELLOW}    lineage_ не найден, пробуем evolution_...${CLR_RESET}"
        if ! lunch "$FALLBACK_LUNCH_1" 2>/dev/null; then
            echo -e "${CLR_YELLOW}    evolution_-version не найден, пробуем evolution_ без версии...${CLR_RESET}"
            lunch "$FALLBACK_LUNCH_2"
        fi
    fi
fi

# ============================================================
# 6. Запуск процесса компиляции и вывода TUI
# ============================================================
TARGET_CMD="${APP_TARGET:-evolution}"
CMD_LABEL="$TARGET_CMD ($JOBS)"

if [ "$CLEAN_OUT" = true ]; then
    echo -e "${CLR_YELLOW}⚠ Снос out/ целиком перед сборкой...${CLR_RESET}"
    rm -rf out
elif [ "$CLEAN_DEVICE" = true ]; then
    echo -e "${CLR_YELLOW}⚠ Удаление out/target/product/$DEVICE_CODE перед сборкой...${CLR_RESET}"
    rm -rf "out/target/product/$DEVICE_CODE"
fi

echo -e "${CLR_CYAN}╭──────────────────────────────────────────────────────────────────────────╮${CLR_RESET}"
printf "${CLR_CYAN}│ ${CLR_GREEN}Запуск сборки:${CLR_RESET} ${CLR_WHITE}%-54s${CLR_RESET} ${CLR_CYAN}│${CLR_RESET}\n" "$CMD_LABEL"
echo -e "${CLR_CYAN}╰──────────────────────────────────────────────────────────────────────────╯${CLR_RESET}"

BUILD_START_TIME=$(date +%s)

# Запускаем компиляцию с парсингом прогресса Ninja на лету
# m nothing -j4 && m "$TARGET_CMD" $JOBS
m "$TARGET_CMD" $JOBS

BUILD_EXIT_CODE=$?
BUILD_END_TIME=$(date +%s)
BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))

echo -e "\n"
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "${CLR_RED}❌ Сборка завершилась с ошибкой! (код $BUILD_EXIT_CODE, длительность ${BUILD_DURATION}с)${CLR_RESET}"
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return "$BUILD_EXIT_CODE"; else exit "$BUILD_EXIT_CODE"; fi
fi

echo -e "${CLR_GREEN}✨ Сборка успешно завершена за ${BUILD_DURATION} сек!${CLR_RESET}"

# ============================================================
# 7. Экспорт релиза (--release / --json)
# ============================================================
if [ "$DO_RELEASE" = true ]; then
    SRC_DIR="out/target/product/$DEVICE_CODE"
    DATE_STR=$(date +%Y%m%d)
    KERNEL_SUFFIX="${TARGET_KERNEL_DIR_EXT:-StockKernel}"

    if [ -n "$CUSTOM_RELEASE_PATH" ]; then
        RELEASE_DIR="$CUSTOM_RELEASE_PATH"
    else
        RELEASE_DIR="$DEFAULT_RELEASE_BASE/$DATE_STR/$DEVICE_CODE/$KERNEL_SUFFIX"
    fi

    echo -e "${CLR_CYAN}=== RELEASE: Экспорт артефактов в $RELEASE_DIR ===${CLR_RESET}"
    mkdir -p "$RELEASE_DIR"

    ZIP_PATH=$(ls -t "$SRC_DIR"/*.zip 2>/dev/null | head -n 1)
    if [ -z "$ZIP_PATH" ]; then
        echo -e "${CLR_RED}❌ Ошибка: Готовый ZIP-архив не найден в $SRC_DIR!${CLR_RESET}"
        if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 1; else exit 1; fi
    fi

    ZIP_NAME=$(basename "$ZIP_PATH")
    echo -e "  ${CLR_GREEN}Копирование ZIP:${CLR_RESET} $ZIP_NAME"
    cp "$ZIP_PATH" "$RELEASE_DIR/"

    IMAGES=("dtbo.img" "vendor_boot.img" "vendor_kernel_boot.img" "boot.img" "init_boot.img")
    for img in "${IMAGES[@]}"; do
        if [ -f "$SRC_DIR/$img" ]; then
            echo -e "  ${CLR_GREEN}Копирование:${CLR_RESET} $img"
            cp "$SRC_DIR/$img" "$RELEASE_DIR/"
        fi
    done

    for vb in "$SRC_DIR"/vbmeta*.img; do
        [ -f "$vb" ] || continue
        echo -e "  ${CLR_GREEN}Копирование:${CLR_RESET} $(basename "$vb")"
        cp "$vb" "$RELEASE_DIR/"
    done

    # Модификация OTA JSON
    if [ "$MODIFY_JSON" = true ]; then
        JSON_SRC="$SRC_DIR/${DEVICE_CODE}.json"
        if [ -f "$JSON_SRC" ]; then
            JSON_DST="$RELEASE_DIR/${ZIP_NAME%.zip}.json"
            echo -e "  ${CLR_GREEN}Модификация OTA JSON...${CLR_RESET}"
            python3 - "$JSON_SRC" "$JSON_DST" <<'PYEOF'
import json, sys
from datetime import datetime

src, dst = sys.argv[1], sys.argv[2]
with open(src, 'r', encoding='utf-8') as f:
    data = json.load(f)

resp = data['response'][0]
resp['maintainer']           = 'LeeGarChat'
resp['oem']                  = 'Google'
resp['buildtype']            = 'user'
resp['forum']                = 'https://t.me/EvoX_LeeGarChat'
resp['paypal']               = 'https://boosty.to/leegar/'
resp['github']               = 'leegarchat'
resp['currently_maintained'] = True

ts = resp.get('timestamp', 0)
try:
    dt = datetime.fromtimestamp(int(ts))
    human = dt.strftime('%Y-%m-%d %H:%M:%S')
    new_resp = {}
    for k, v in resp.items():
        new_resp[k] = v
        if k == 'timestamp':
            new_resp['_timestamp_readable']    = human + ' (локальный часовой пояс)'
            new_resp['_timestamp_convert_cmd'] = "date -d '" + human + "' +%s"
            new_resp['_timestamp_note']        = 'Редактируйте _timestamp_readable, затем запустите _timestamp_convert_cmd'
    data['response'][0] = new_resp
except Exception:
    pass

with open(dst, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print('OK')
PYEOF
            echo -e "  ${CLR_GREEN}✓ OTA JSON сохранен:${CLR_RESET} $(basename "$JSON_DST")"
        fi
    fi

    echo -e "${CLR_GREEN}✓ Релиз сформирован успешно!${CLR_RESET}\n"

    # Touch ключевых img текущим временем — свежие файлы видно сразу
    touch "out/target/product/$DEVICE_CODE"/boot.img \
        "out/target/product/$DEVICE_CODE"/dtbo.img \
        "out/target/product/$DEVICE_CODE"/init_boot.img \
        "out/target/product/$DEVICE_CODE"/vendor_boot.img \
        "out/target/product/$DEVICE_CODE"/vendor_kernel_boot.img \
        "out/target/product/$DEVICE_CODE"/vbmeta.img \
        "out/target/product/$DEVICE_CODE"/vbmeta_system.img \
        "out/target/product/$DEVICE_CODE"/vbmeta_vendor.img 2>/dev/null || true
fi

# Корректный выход: return для source, exit для прямого запуска
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 0
else
    exit 0
fi