# EvolutionX Unofficial — Pixel 8 Series

[English](../en/README.md) | **Русский**

`Guide v1 · 2026-10-14 · ROM 12.3`

Неофициальный EvolutionX (Android 17) для Pixel 8 / 8 Pro / 8a.
User-сборка, GApps внутри. KernelSU + OrangeFox уже вшиты — ничего дошивать не надо.

<details>
<summary>🔥 Зачем эта сборка</summary>

- **Движок PEP** — десятки живых твиков: сетка лаунчера, блюр шторки, иконки, физика скролла, анимации. → [гайд PEP](PixelExtraParts.md)
- **AutoLock-сторож** — блокирует экран по таймеру, даже если приложение не даёт уснуть, ставит медиа на паузу.
- **Буст на солнце + насыщенность** — железные контролы яркости и цвета.
- **Режимы нагрева** — 5 режимов Tensor, переключаются за секунды, отдельно на игру.
- **Тумблеры СИМ** — VoLTE, Wi-Fi звонки, VoNR, Cross-SIM, пороги 5G.
- **Всё из коробки** — OrangeFox в `vendor_boot`, ядро WildKSU, Face Unlock дружит с банками.

</details>

<details>
<summary>📱 Устройства</summary>

- Pixel 8 — `shiba`
- Pixel 8 Pro — `husky`
- Pixel 8a — `akita`

У каждого своя папка загрузок. → [Ссылки](LINKS.md)

</details>

## Установка — коротко

1. Разблокируйте bootloader (телефон сотрётся).
2. Прошейте OrangeFox `vendor_boot`, перезагрузитесь в рекавери. → [гайд OrangeFox](OrangeFox.md)
3. Прошейте zip прошивки — sideload или из памяти / USB-OTG.
4. **Format Data** — обязателен при переходе со стока или другой прошивки.
   В OrangeFox: Menu → Manage Partitions → Data → Format Data → ввести `yes`.
   (Обычный wipe не считается.)
5. Перезагрузка. Готово.

Magisk опционален: сначала прошейте стоковый `boot` (KernelSU по умолчанию, они конфликтуют).

<details>
<summary>📴 Без рута — стоковый boot</summary>

- Прошейте стоковый `boot.img` под устройство — через OrangeFox (файл →
  раздел Boot) или fastboot (`fastboot flash boot boot_stock.img`).
- Pixel 8 ([Drive](https://drive.google.com/drive/folders/1_anleHdh9kraNcrpDnJXv1WyfWxiUYQw?usp=drive_link)) ·
  8 Pro ([Drive](https://drive.google.com/drive/folders/1fcWUNDVoxFCkImUT9eIHynfDtl4W8qpH?usp=drive_link)) ·
  8a ([Drive](https://drive.google.com/drive/folders/1FT6zbBcbrQGhL1-ZJsFgLBpDpUZsi700?usp=drive_link))
- Один образ на **все A17 сборки** (вендорский блоб общий). Если блобы сменятся,
  новый образ + его диапазон совместимости появятся здесь отдельно.

</details>

<details>
<summary>❓ Вопрос → ответ</summary>

- **Где скачать?** → [Ссылки](LINKS.md#rom)
- **Как поставить рекавери?** → [гайд OrangeFox](OrangeFox.md)
- **Drive пишет quota exceeded?** → [Ссылки](LINKS.md#загрузки-rom): откройте папку,
  Make a copy на свой Drive, качайте клон.
- **Обновиться без вайпа?** → Накатите новый zip поверх старой сборки, формат не нужен. Формат — только со стока / чужих прошивок.
- **MD5 не сошёлся?** → Битый файл. Качайте заново, не шейте его.
- **Бутлуп?** → Шлите логи (`flog.sh` в рекавери) в [группу поддержки](https://t.me/LeeGarChatEvox). Нет логов = нет фикса.
- **Банки?** → Pixel Face Unlock (Class 3) с ними работает.
- **Что изменилось?** → [Чанджлог](CHANGELOG.md)
- **Что умеет PEP?** → [гайд PEP](PixelExtraParts.md)

</details>

## Дальше

- 📖 [Установка OrangeFox](OrangeFox.md) — типы A/B, бэкапы, команды
- 📝 [Чанджлог](CHANGELOG.md) — история по сборкам
- ✨ [Фишки PEP](PixelExtraParts.md) — полный гид со скриншотами
- 🔗 [Ссылки](LINKS.md) — загрузки, чаты, донат
- 👤 Мейнтейнер: [@LeeGarGold](https://t.me/LeeGarGold) / [@LeeGarChat](https://t.me/LeeGarChat)

<details>
<summary>📦 Исходники этой сборки</summary>

- Скрипты сборки + упаковка OrangeFox: [device_google_build](https://github.com/leegarchat/device_google_build)
- Древа устройств: [shusky](https://github.com/leegarchat/android_device_google_shusky) ·
  [zuma](https://github.com/leegarchat/android_device_google_zuma) ·
  [akita](https://github.com/leegarchat/android_device_google_akita)
- PEP: [PixelExtraParts](https://github.com/leegarchat/PixelExtraParts)
- Вендоры (частично — большие файлы вроде GCam не влезли, достать локально):
  [akita](https://github.com/leegarchat/proprietary_vendor_google_akita) ·
  [husky](https://github.com/leegarchat/proprietary_vendor_google_husky) ·
  [shiba](https://github.com/leegarchat/proprietary_vendor_google_shiba) ·
  база: [TheMuppets](https://github.com/TheMuppets)
- Ядра + скрипты сборки: [pixel-kernels](https://github.com/leegarchat/pixel-kernels)
- Исходники OrangeFox: [twrp_device_google_pixels](https://github.com/leegarchat/twrp_device_google_pixels)
- Мелочи: JamesDSP (из crDroid), слегка модифицированный FaceUnlock vendor.

</details>
