# EvolutionX Unofficial — Pixel 8 Series

[English](../en/README.md) | **Русский**

`Guide v1 · 2026-10-14 · ROM 12.3`

Неофициальный EvolutionX (Android 17) для Pixel 8 / 8 Pro / 8a.
User-сборка, GApps внутри. OrangeFox + WildKSU уже в zip прошивки —
но для первой прошивки OrangeFox всё равно нужен.

<details>
<summary>⚠️ Сначала прочитайте — это сотрёт телефон</summary>

- Это **НЕ обычное обновление**. Разблокировка + чистая прошивка **удаляют всё**:
  фото, чаты, файлы. Сохраните их заранее.
- **Не начинайте, если:** это единственный телефон и он нужен завтра; нужны
  банки / рабочие приложения без риска; командную строку ПК видите впервые.
- Сложность: **средняя**. Время: ~30–40 мин + первая загрузка 5–10 мин на лого (норма).
  Нужны: ПК (Windows/Linux), кабель, батарея 60%+.

</details>

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

## Установка — начисто (со стока / чужой прошивки)

<details>
<summary>☑️ Перед стартом — чеклист для Windows</summary>

- **Бэкап**: фото, чаты, файлы — с телефона (ПК / облако). Разблокировка сотрёт всё.
- **Батарея 60%+**, родной кабель, при глюках fastboot — порт USB 2.0.
- **Скачайте** zip ПОД СВОЁ устройство ([Ссылки](LINKS.md#загрузки-rom)).
  Проверьте **MD5** со значением рядом с zip:
  `certutil -hashfile file.zip MD5`. Должен совпасть буква в букву.
- **Инструменты ПК**: [platform-tools](https://developer.android.com/tools/releases/platform-tools)
  (adb/fastboot) + **Google USB driver**. Проверка: `fastboot devices` видит телефон.
- **На телефоне**: включите Developer options → **OEM unlocking** + **USB debugging**.

</details>

1. Разблокируйте bootloader (телефон сотрётся):
   `adb reboot bootloader`, затем `fastboot flashing unlock` — подтвердить на экране.
2. Прошейте OrangeFox `vendor_boot`, перезагрузитесь в рекавери. → [гайд OrangeFox](OrangeFox.md)
   (На стоке + Windows: тип A, способ 2 — остальное не смотрите.)
3. Прошейте zip прошивки. В OrangeFox: режим sideload → на ПК `adb sideload rom.zip`.
   Или скопируйте zip на USB-OTG → Install → выбрать файл (~5 мин).
4. **Format Data** — здесь обязателен.
   В OrangeFox: Menu → Manage Partitions → Data → Format Data → ввести `yes`.
   (Обычный wipe не считается.)
5. Перезагрузка. Первая загрузка 5–10 мин — ждите. Готово.

## Обновление — грязно (12.x → новая, без вайпа)

- Накатите новый zip поверх старой сборки sideload-ом. Format не нужен.
- Если убирали рут стоковым `boot`, обновление вернёт рут (WildKSU в прошивке) —
  прошейте стоковый boot заново, чтобы остаться без рута.

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
- **Обновиться без вайпа?** → Только внутри одной прошивки: накатить поверх, без формата.
  Со стока / чужих: начисто с форматом. → [выше](#обновление--грязно-12x--новая-без-вайпа)
- **MD5 не сошёлся?** → Битый файл. Качайте заново, не шейте его.
- **Какой слот?** → У Pixel два слота (A/B). `--slot=all` шьёт оба = надёжнее.
  Свой: `fastboot getvar current-slot`.
- **Бэкапы скопируйте с телефона ДО Format Data** — формат трёт внутреннюю
  память вместе с `/sdcard`-бэкапами. Сначала `adb pull` на ПК.
- **Бутлуп?** → Шлите логи (`flog.sh` в рекавери) в [группу поддержки](https://t.me/LeeGarChatEvox). Нет логов = нет фикса.
- **Банки / Wallet / рабочие?** → Прошивка с рутом по умолчанию (WildKSU).
  Сам Face Unlock для входа работает, но **рут может палить детект**
  банков, Wallet или Intune. Нужен ноль риска? Убирайте рут (блок стокового boot выше).
- **Назад в сток + relock?** → Прошейте заводские образы, затем `fastboot flashing lock`.
  Лочить только на 100% стоке, иначе кирпич.
- **Сколько висит первая загрузка?** → 5–10 мин на лого — норма. Паника после 20.
- **Что изменилось?** → [Чанджлог](CHANGELOG.md)
- **Что умеет PEP?** → [гайд PEP](PixelExtraParts.md)

</details>

<details>
<summary>📖 Слова (10 must-know)</summary>

- **shiba / husky / akita** — заводские имена Pixel 8 / 8 Pro / 8a.
- **Bootloader** — запускает телефон до Android. Разблокировка трёт все данные.
- **Рекавери (OrangeFox)** — мини-система для прошивки zip и формата.
- **`vendor_boot`** — раздел, где на Pixel 8 живёт рекавери.
- **Sideload** — отправка zip с ПК (`adb sideload`) в рекавери.
- **Слоты A/B** — две копии системы; обновление едет в свободную.
- **WildKSU / KernelSU / reSukiSU** — варианты рута. По умолчанию у вас WildKSU.
- **GApps** — гуглосервисы, уже внутри. Дшивать ничего не надо.
- **Format Data vs wipe** — формат трёт всё включая фото; wipe — нет.
- **MD5** — отпечаток файла. Не сошёлся = битая загрузка.
- **PEP** — приложение PixelExtraParts со всеми твиками.
- **`flog.sh`** — одна команда в рекавери, пакует логи для багрепорта.

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
