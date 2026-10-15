# EvolutionX Unofficial — Pixel 8 Series

**English** | [Русский](../ru/README.md)

`Guide v1 · 2026-10-14 · ROM 12.3`

Unofficial EvolutionX (Android 17) for Pixel 8 / 8 Pro / 8a.
User build, GApps inside. The ROM zip already contains OrangeFox + WildKSU —
you still need OrangeFox once to flash it the first time.

<details>
<summary>⚠️ Read first — this erases your phone</summary>

- This is **NOT a normal update**. Unlocking + clean flash **deletes everything**:
  photos, chats, files. Back them up first.
- **Don't start if:** this is your only phone and you need it tomorrow; you need
  banking / work apps with zero risk; you never used a PC command line.
- Difficulty: **medium**. Time: ~30–40 min + first boot 5–10 min on logo (normal).
  Needs: a PC (Windows/Linux), USB cable, battery 60%+.

</details>

<details>
<summary>🔥 Why this build</summary>

- **PEP engine** — dozens of live tweaks: launcher grid, shade blur, icons, scroll physics, animations. → [PEP guide](PixelExtraParts.md)
- **AutoLock guard** — locks the screen on timer even when apps hold it awake, pauses media.
- **Sun boost + saturation** — hardware brightness and color controls.
- **Heat profiles** — 5 Tensor modes, switch in seconds, per game.
- **SIM toggles** — VoLTE, Wi-Fi calling, VoNR, Cross-SIM, 5G thresholds.
- **Ready out of box** — OrangeFox in `vendor_boot`, WildKSU kernel, Face Unlock works with banking apps.

</details>

<details>
<summary>📱 Devices</summary>

- Pixel 8 — `shiba`
- Pixel 8 Pro — `husky`
- Pixel 8a — `akita`

Each has its own download folder. → [Links](LINKS.md)

</details>

## Install — clean (from stock / other ROM)

<details>
<summary>☑️ Before you start — Windows checklist</summary>

- **Backup**: photos, chats, files — off the phone (PC / cloud). Unlock wipes all.
- **Battery 60%+**, original cable, USB 2.0 port if fastboot is flaky.
- **Download** the zip for YOUR device ([Links](LINKS.md#rom-downloads)).
  Check **MD5** against the value posted next to the zip:
  `certutil -hashfile file.zip MD5`. Must match exactly.
- **PC tools**: [platform-tools](https://developer.android.com/tools/releases/platform-tools)
  (adb/fastboot) + **Google USB driver**. Test: `fastboot devices` shows your phone.
- **On the phone**: enable Developer options → **OEM unlocking** + **USB debugging**.

</details>

1. Unlock the bootloader (wipes the phone):
   `adb reboot bootloader`, then `fastboot flashing unlock` — confirm on screen.
2. Flash OrangeFox `vendor_boot`, reboot to recovery. → [OrangeFox guide](OrangeFox.md)
   (On stock + Windows: Type A, Way 2 — ignore the rest.)
3. Flash the ROM zip. In OrangeFox: sideload mode → on PC `adb sideload rom.zip`.
   Or copy the zip to USB-OTG → Install → pick file (~5 min).
4. **Format Data** — mandatory here.
   In OrangeFox: Menu → Manage Partitions → Data → Format Data → type `yes`.
   (A plain wipe is not enough.)
5. Reboot. First boot takes 5–10 min — wait. Done.

## Update — dirty (12.x → new build, no wipe)

- Sideload the new zip over the old build. No Format needed.
- If you unrooted via stock `boot`, the update re-roots (WildKSU is in the ROM) —
  re-flash stock boot after updating if you want to stay unrooted.

Magisk is optional: flash stock `boot` first (KernelSU is default, they conflict).

<details>
<summary>📴 Going unrooted — stock boot</summary>

- Flash the stock `boot.img` for your device — via OrangeFox (pick file →
  Boot partition) or fastboot (`fastboot flash boot boot_stock.img`).
- Pixel 8 ([Drive](https://drive.google.com/drive/folders/1_anleHdh9kraNcrpDnJXv1WyfWxiUYQw?usp=drive_link)) ·
  8 Pro ([Drive](https://drive.google.com/drive/folders/1fcWUNDVoxFCkImUT9eIHynfDtl4W8qpH?usp=drive_link)) ·
  8a ([Drive](https://drive.google.com/drive/folders/1FT6zbBcbrQGhL1-ZJsFgLBpDpUZsi700?usp=drive_link))
- One image fits **all A17 builds** (same vendor blob). If vendor blobs ever
  change, a new image + its compatible range will be linked here separately.

</details>

<details>
<summary>❓ Questions → answers</summary>

- **Where to download?** → [Links](LINKS.md#rom)
- **How to install recovery?** → [OrangeFox guide](OrangeFox.md)
- **Drive says quota exceeded?** → [Links](LINKS.md#rom-downloads): open the folder,
  Make a copy to your Drive, download the clone.
- **Update without wipe?** → Only same-ROM updates: sideload over, no format.
  From stock / other ROMs: clean flash with Format. → [above](#update--dirty-12x--new-build-no-wipe)
- **MD5 mismatch?** → Broken download. Re-download, never flash it.
- **Which slot?** → Pixel has two slots (A/B). `--slot=all` flashes both = safer.
  Check yours: `fastboot getvar current-slot`.
- **Copy backups off the phone BEFORE Format Data** — Format wipes internal
  storage including `/sdcard` backups. `adb pull` them to PC first.
- **Bootloop?** → Send logs (`flog.sh` in recovery) to the [support group](https://t.me/LeeGarChatEvox). No logs = no fix.
- **Banking / Wallet / work apps?** → The ROM is rooted by default (WildKSU).
  Face Unlock itself works with banking login, but **root can trip detection**
  in banking, Wallet or Intune. Need zero risk? Go unrooted (stock boot block above).
- **Back to stock + relock?** → Flash factory images, then `fastboot flashing lock`.
  Only relock on 100% stock, or you brick.
- **How long is first boot?** → 5–10 min on logo is normal. Worry after 20.
- **What changed in this build?** → [Changelog](CHANGELOG.md)
- **What can PEP do?** → [PEP guide](PixelExtraParts.md)

</details>

<details>
<summary>📖 Words (10 must-know)</summary>

- **shiba / husky / akita** — Pixel 8 / 8 Pro / 8a factory codenames.
- **Bootloader** — starts the phone before Android. Unlocking it wipes all data.
- **Recovery (OrangeFox)** — mini-system for flashing zips and formatting.
- **`vendor_boot`** — partition where recovery lives on Pixel 8.
- **Sideload** — sending the zip from PC (`adb sideload`) to recovery.
- **Slots A/B** — two system copies; update goes to the idle one.
- **WildKSU / KernelSU / reSukiSU** — root variants. You get WildKSU by default.
- **GApps** — Google apps/services, already inside. Flash nothing extra.
- **Format Data vs wipe** — format erases everything incl. photos; wipe doesn't.
- **MD5** — file fingerprint. Mismatch = broken download.
- **PEP** — PixelExtraParts settings app with all tweaks.
- **`flog.sh`** — one command in recovery that packs logs for a bug report.

</details>

## Go deeper

- 📖 [Install OrangeFox](OrangeFox.md) — Type A/B, backups, commands
- 📝 [Changelog](CHANGELOG.md) — per-build history
- ✨ [PEP features](PixelExtraParts.md) — full user guide with screenshots
- 🔗 [Links](LINKS.md) — downloads, chats, donate
- 👤 Maintainer: [@LeeGarGold](https://t.me/LeeGarGold) / [@LeeGarChat](https://t.me/LeeGarChat)

<details>
<summary>📦 Sources behind this build</summary>

- Build scripts + OrangeFox packing: [device_google_build](https://github.com/leegarchat/device_google_build)
- Device trees: [shusky](https://github.com/leegarchat/android_device_google_shusky) ·
  [zuma](https://github.com/leegarchat/android_device_google_zuma) ·
  [akita](https://github.com/leegarchat/android_device_google_akita)
- PEP: [PixelExtraParts](https://github.com/leegarchat/PixelExtraParts)
- Vendors (partial — big files like GCam didn't fit, re-extract locally):
  [akita](https://github.com/leegarchat/proprietary_vendor_google_akita) ·
  [husky](https://github.com/leegarchat/proprietary_vendor_google_husky) ·
  [shiba](https://github.com/leegarchat/proprietary_vendor_google_shiba) ·
  base: [TheMuppets](https://github.com/TheMuppets)
- Kernels + build scripts: [pixel-kernels](https://github.com/leegarchat/pixel-kernels)
- OrangeFox sources: [twrp_device_google_pixels](https://github.com/leegarchat/twrp_device_google_pixels)
- Extras: JamesDSP (from crDroid), slightly modified FaceUnlock vendor.

</details>
