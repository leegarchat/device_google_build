# EvolutionX Unofficial — Pixel 8 Series

**English** | [Русский](../ru/README.md)

`Guide v1 · 2026-10-14 · ROM 12.3`

Unofficial EvolutionX (Android 17) for Pixel 8 / 8 Pro / 8a.
User build, GApps inside. KernelSU + OrangeFox recovery already in — no extra flashing.

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

## Install — short path

1. Unlock the bootloader (wipes the phone).
2. Flash OrangeFox `vendor_boot`, reboot to recovery. → [OrangeFox guide](OrangeFox.md)
3. Flash the ROM zip — sideload or from storage / USB-OTG.
4. **Format Data** — mandatory when coming from stock or another ROM.
   In OrangeFox: Menu → Manage Partitions → Data → Format Data → type `yes`.
   (A plain wipe is not enough.)
5. Reboot. Done.

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
- **Update without wipe?** → Sideload the new zip over the old build, no format needed. Format only from stock / other ROMs.
- **MD5 mismatch?** → Broken download. Re-download, never flash it.
- **Bootloop?** → Send logs (`flog.sh` in recovery) to the [support group](https://t.me/LeeGarChatEvox). No logs = no fix.
- **Banking apps?** → Pixel Face Unlock (Class 3) works with them.
- **What changed in this build?** → [Changelog](CHANGELOG.md)
- **What can PEP do?** → [PEP guide](PixelExtraParts.md)

</details>

## Go deeper

- 📖 [Install OrangeFox](OrangeFox.md) — all 6 ways, backups, types A/B/C
- 📝 [Changelog](CHANGELOG.md) — per-build history
- ✨ [PEP features](PixelExtraParts.md) — full user guide with screenshots
- 🔗 [Links](LINKS.md) — downloads, guides, chats, donate
- 👤 Maintainer: [@LeeGarGold](https://t.me/LeeGarGold) / [@LeeGarChat](https://t.me/LeeGarChat)
