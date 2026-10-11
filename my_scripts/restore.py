#!/usr/bin/env python3
"""
restore_from_original.py - Быстрый перенос сохраненных файлов из bakFiles/original в рабочее дерево.
"""

import os
import shutil
import subprocess
from pathlib import Path

ORIG_DIR = Path("bakFiles/original")

def get_target_uid_gid() -> tuple[int, int]:
    sudo_uid = os.environ.get("SUDO_UID")
    sudo_gid = os.environ.get("SUDO_GID")
    if sudo_uid and sudo_gid:
        return int(sudo_uid), int(sudo_gid)
    return os.getuid(), os.getgid()

def fix_permissions(path: Path, uid: int, gid: int):
    if uid == 0 or not path.exists():
        return
    try:
        subprocess.run(["chown", f"{uid}:{gid}", str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    if not ORIG_DIR.exists():
        print(f"❌ Ошибка: Каталог '{ORIG_DIR}' не найден!")
        return

    uid, gid = get_target_uid_gid()
    restored_count = 0

    print(f"[*] Сканирование файлов в '{ORIG_DIR}'...\n")

    for src_file in sorted(ORIG_DIR.rglob("*")):
        if not src_file.is_file():
            continue

        rel_path = src_file.relative_to(ORIG_DIR)
        rel_path_str = str(rel_path).replace("\\", "/")

        # Корректное снятие суффикса .bak для билд-файлов Android
        if rel_path_str.endswith(".bak"):
            base_rel = rel_path_str[:-4]
            if Path(base_rel).name in ("Android.bp", "Android.mk"):
                rel_path_str = base_rel

        target_file = Path(rel_path_str)

        # Создаем каталог назначения, если его нет
        target_file.parent.mkdir(parents=True, exist_ok=True)

        # Перезаписываем файл в дереве исходников
        shutil.copy2(src_file, target_file)
        fix_permissions(target_file, uid, gid)

        print(f"  ✓ Накачен: {rel_path_str}")
        restored_count += 1

    print(f"\n✨ Готово! Все изменения ({restored_count} файлов) успешно возвращены в дерево.")

if __name__ == "__main__":
    main()