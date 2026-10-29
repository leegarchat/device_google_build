# Установка OrangeFox (Pixel 8 серия)

[English](../en/OrangeFox.md) | **Русский**

`Guide v2 · 2026-10-14 · payload 16_1-aio`

> База рекавери R12/A16 — на ROM A17 работает нормально, версии рекавери
> и системы тут независимы.

Два типа установки. **Тип A (AIO zip) — основной путь** — умный установщик,
бэкап, побайтовая проверка. **Тип B (BootStaff-образ)** — прямая прошивка, без установщика.

> **На стоке + Windows? Делайте тип A, способ 2 ниже — остальное не смотрите.**
> Способы 3–5 требуют рут / рекавери / второй телефон, которых пока нет.

> На Pixel 8 рекавери живёт только в `vendor_boot`.
> Шить `boot`, `dtbo` или `init_boot` ради рекавери не надо.

<details>
<summary>✅ Перед стартом</summary>

- Bootloader **разблокирован**.
- Проверьте **MD5** до прошивки:
  - Linux: `md5sum file`
  - Windows: `certutil -hashfile file MD5`
- Не сошёлся = битая загрузка. Качайте заново, не репортьте.

</details>

<details>
<summary>📥 Загрузки</summary>

- **Тип A — aio.zip**: [ссылка](https://github.com/leegarchat/twrp_device_google_pixels/releases)
- **Тип B — BootStaff-образы**: внутри каждой папки релиза → `Boot_staff`,
  те же папки, что ROM.

</details>

## Тип A — AIO zip (основной путь)

Стоковый `vendor_boot` не трогает (first stage, cmdline, dlkm остаются),
меняет только часть рекавери, бэкапит оба слота, проверяет прошивку побайтово.

<details>
<summary>📦 Распаковывать или нет?</summary>

- **Установка с ПК (способы 1–2): zip РАСПАКОВАТЬ.** Нужны живые файлы:
  `install-desktop.sh`, `install-desktop.bat`, `export.txt`, `bin/`, один `*.ramdisk.lz4`.
  Запуск из окна архиватора не работает никогда.
- **Менеджер / рекавери (способы 3–4): НЕ распаковывать.** Шейте `.zip` как есть.

</details>

<details>
<summary>1. ПК / Linux</summary>

- Телефон в **bootloader** (Громкость вниз + Power), кабель в ПК.
- Запустите `./install-desktop.sh` (или двойной клик по AppImage).

</details>

<details>
<summary>2. ПК / Windows</summary>

- Телефон в **bootloader**, кабель в ПК.
- Запустите `install-desktop.bat` (или двойной клик по `.exe`).
- Первый раз в жизни: поставьте **Google USB driver**, иначе fastboot телефона не увидит.
- Окно моргнуло и закрылось — запустите из `cmd` в той папке, чтобы прочитать ошибку.

</details>

<details>
<summary>3. Magisk / KernelSU / APatch</summary>

- Прошейте zip в менеджере как модуль.
- Это **не** модуль: установка постоянная, после себя удаляется.

</details>

<details>
<summary>4. Любое рекавери (OFox / TWRP / Lineage)</summary>

- Install → выберите zip → свайп.
- В Lineage recovery: ADB Sideload → `adb sideload file.zip`.

</details>

<details>
<summary>5. Termux (телефон-в-телефон по OTG)</summary>

- Цель подключите по USB-OTG.
- Как Linux (`./install-desktop.sh`), но сначала: `pkg install android-tools`.

</details>

> ARM64 ПК / Termux: встроенные tools только x64 — поставьте platform-tools
> системно заранее. 32-битные системы не поддерживаются.

## Тип B — BootStaff-образ (прямая прошивка)

Готовый `vendor_boot.img` под устройство, шьётся напрямую. Без бэкапа,
без меню — знайте свой слот.

<details>
<summary>Через fastboot (ПК)</summary>

- Телефон в **bootloader**, кабель в ПК.
- Только активный слот: `fastboot flash vendor_boot vendor_boot.img`
- Оба слота (надёжнее): `fastboot flash --slot=all vendor_boot vendor_boot.img`
- **Сразу** перезагрузка в рекавери, в систему пока не грузиться:
  `fastboot reboot recovery`

</details>

<details>
<summary>На телефоне (нужен рут)</summary>

- Положите `.img` во внутреннюю память (`/sdcard/vendor_boot.img`).
- В root-терминале (`su`):
  - Активный слот: `dd if=/sdcard/vendor_boot.img of=/dev/block/by-name/vendor_boot$(getprop ro.boot.slot_suffix)`
  - Оба слота: два прогона `dd` с `vendor_boot_a` и `vendor_boot_b`.
- Проверьте вывод на ошибки, перезагрузитесь в рекавери.

</details>

<details>
<summary>💾 Бэкапы (тип A)</summary>

- Стоковые слоты бэкапятся сами (папка с датой).
- Установка с ПК: бэкап + `install.log` в `backup/<дата-время>/` рядом со скриптом.
- На устройстве: `/sdcard/backup_vendor_boot/`.
- Успех = `RESULT: OK` на экране. Первая загрузка в рекавери — до 60 секунд.
- **Бэкап скопируйте с телефона ДО Format Data прошивки** —
  формат трёт и `/sdcard/backup_vendor_boot/`. Сначала `adb pull` на ПК.
- Восстановление: установщик → Restore → выбрать бэкап. Шьётся как есть.

</details>

<details>
<summary>⌨️ Полезные команды</summary>

- `fastboot devices` — телефон виден в bootloader?
- `adb reboot bootloader` / `adb reboot recovery` — перезагрузка туда из системы.
- `adb shell flog.sh` — пачка логов без касания телефона.

</details>

<details>
<summary>🆘 Застряли — сначала логи</summary>

- В рекавери: `flog.sh` (или `adb shell flog.sh`). Один архив + модель.
- Репорт в чат Pixel 8: [zuma](https://t.me/OFRP_tensor_g3).
- Нет логов = нет фикса.

</details>
