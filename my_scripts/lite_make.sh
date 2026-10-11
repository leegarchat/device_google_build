#!/bin/bash
# lite_make.sh — source env + lunch + сборка ОТДЕЛЬНЫХ soong-модулей (без полного ROM).
# Синтаксис lunch как в make_n.sh: lineage_<device>-<ver>-<type> с фолбэками.
#
# Использование:
#   lite_make.sh [-d shiba] [-t user] [-v cp2a] [-j 8] <soong-модуль> [модуль...]
# Примеры:
#   lite_make.sh LsplantInject
#   lite_make.sh -d akita PixelCustomPartsSystem liblsplant liblspbridge
# shellcheck disable=SC1091

DEVICE_CODE="shiba"
BUILD_TYPE="user"
VERSION_PART="cp2a"
JOBS="-j8"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--device) DEVICE_CODE="$2"; shift 2 ;;
        -t|--type) BUILD_TYPE="$2"; shift 2 ;;
        -v|--version) VERSION_PART="$2"; shift 2 ;;
        -j|--jobs) JOBS="-j$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [-d device] [-t user|userdebug|eng] [-v cp2a] [-j N] <module> [module...]"
            exit 0 ;;
        *) break ;;
    esac
done

if [[ $# -eq 0 ]]; then
    echo "❌ Укажи soong-модуль: $0 LsplantInject" >&2
    exit 1
fi

# Корень древа: my_scripts -> build -> google -> device -> root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$TREE_ROOT" || exit 1

if ! type -t m >/dev/null 2>&1; then
    echo "--> source build/envsetup.sh"
    source build/envsetup.sh
fi

PRIMARY_LUNCH="lineage_${DEVICE_CODE}-${VERSION_PART}-${BUILD_TYPE}"
if [[ "${TARGET_PRODUCT:-}" != *"$DEVICE_CODE"* ]] || [[ "${TARGET_BUILD_VARIANT:-}" != "$BUILD_TYPE" ]]; then
    echo "--> lunch $PRIMARY_LUNCH"
    if ! lunch "$PRIMARY_LUNCH" 2>/dev/null; then
        echo "    lineage_ не найден, пробуем evolution_..."
        if ! lunch "evolution_${DEVICE_CODE}-${VERSION_PART}-${BUILD_TYPE}" 2>/dev/null; then
            lunch "evolution_${DEVICE_CODE}-${BUILD_TYPE}"
        fi
    fi
else
    echo "--> lunch уже активен: $TARGET_PRODUCT-$TARGET_BUILD_VARIANT"
fi

echo "--> m $* $JOBS"
m "$@" $JOBS
