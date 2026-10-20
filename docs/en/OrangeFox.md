# Install OrangeFox (Pixel 8 series)

**English** | [Русский](../ru/OrangeFox.md)

`Guide v2 · 2026-10-14 · payload 16_1-aio`

> Recovery source base is R12/A16 — works fine on the A17 ROM, recovery
> and system versions are independent here.

Two install types. **Type A (AIO zip) is the main path** — smart installer,
backup, byte-check. **Type B (BootStaff image)** — direct flash, no installer.

> **On stock + Windows? Do Type A, Way 2 below — ignore the rest.**
> Ways 3–5 need root / recovery / a second phone you don't have yet.

> Pixel 8 series = recovery lives in `vendor_boot` only.
> No need to flash `boot`, `dtbo` or `init_boot` for recovery.

<details>
<summary>✅ Before you start</summary>

- Bootloader **unlocked**.
- Check the **MD5** before flashing:
  - Linux: `md5sum file`
  - Windows: `certutil -hashfile file MD5`
- Mismatch = broken download. Re-download, never report it.

</details>

<details>
<summary>📥 Downloads</summary>

- **Type A — aio.zip**: [link](https://drive.google.com/drive/folders/1S75nhHK3bSB8Au2ajkh46vGqCCqvTjCT)
- **Type B — BootStaff images**: inside each release folder → `BootStaff/Recovery`,
  same folders as the ROM.

</details>

## Type A — AIO zip (main path)

Keeps your stock `vendor_boot` layout (first stage, cmdline, dlkm untouched),
replaces only the recovery part, backs up both slots, byte-checks the flash.

<details>
<summary>📦 Unpack or not?</summary>

- **PC install (ways 1–2): UNPACK the zip first.** You need real files:
  `install-desktop.sh`, `install-desktop.bat`, `export.txt`, `bin/`, one `*.ramdisk.lz4`.
  Running from inside the archiver window never works.
- **Manager / recovery install (ways 3–4): do NOT unpack.** Flash the `.zip` as-is.

</details>

<details>
<summary>1. PC / Linux</summary>

- Phone in **bootloader** mode (Volume Down + Power), connect USB.
- Run `./install-desktop.sh` (or double-click the AppImage).

</details>

<details>
<summary>2. PC / Windows</summary>

- Phone in **bootloader** mode, connect USB.
- Run `install-desktop.bat` (or double-click the `.exe`).
- First time ever: install the **Google USB driver**, or fastboot won't see the phone.
- If the window flashes and closes — run it from `cmd` in that folder to read the error.

</details>

<details>
<summary>3. Magisk / KernelSU / APatch</summary>

- Flash the zip in the manager app like a module.
- It is **not** a module: install is permanent, it deletes itself after.

</details>

<details>
<summary>4. Any recovery (OFox / TWRP / Lineage)</summary>

- Install → pick the zip → swipe.
- In Lineage recovery: ADB Sideload → `adb sideload file.zip`.

</details>

<details>
<summary>5. Termux (phone-to-phone over OTG)</summary>

- Connect the target phone via USB-OTG.
- Same as Linux (`./install-desktop.sh`), but first: `pkg install android-tools`.

</details>

> ARM64 PCs / Termux: bundled tools are x64-only — install platform-tools
> system-wide first. 32-bit systems are not supported.

## Type B — BootStaff image (direct flash)

The ready `vendor_boot.img` for your device, flashed directly. No backup,
no menus — know your slot.

<details>
<summary>Via fastboot (PC)</summary>

- Phone in **bootloader** mode, connect USB.
- Active slot only: `fastboot flash vendor_boot vendor_boot.img`
- Both slots (safer): `fastboot flash --slot=all vendor_boot vendor_boot.img`
- **Immediately** reboot to recovery, don't boot system yet:
  `fastboot reboot recovery`

</details>

<details>
<summary>On the phone (root needed)</summary>

- Put the `.img` on internal storage (`/sdcard/vendor_boot.img`).
- In a root terminal (`su`):
  - Active slot: `dd if=/sdcard/vendor_boot.img of=/dev/block/by-name/vendor_boot$(getprop ro.boot.slot_suffix)`
  - Both slots: two `dd` runs with `vendor_boot_a` and `vendor_boot_b`.
- Check output for errors, reboot to recovery.

</details>

<details>
<summary>💾 Backups (Type A)</summary>

- Stock slots are backed up automatically (dated folder).
- PC install: backup + `install.log` in `backup/<date-time>/` next to the script.
- On-device: `/sdcard/backup_vendor_boot/`.
- Success = `RESULT: OK` on screen. First boot to recovery can take up to 60 seconds.
- **Copy the backup off the phone BEFORE the ROM's Format Data** —
  Format wipes `/sdcard/backup_vendor_boot/` too. `adb pull` it to PC first.
- To restore: installer → Restore → pick backup. Restored bytes are flashed as-is.

</details>

<details>
<summary>⌨️ Handy commands</summary>

- `fastboot devices` — phone visible in bootloader?
- `adb reboot bootloader` / `adb reboot recovery` — reboot there from system.
- `adb shell flog.sh` — log bundle without touching the phone.

</details>

<details>
<summary>🆘 If stuck — logs first</summary>

- In recovery run: `flog.sh` (or `adb shell flog.sh`). One bundle, attach it + device model.
- Report to the Pixel 8 chat: [zuma](https://t.me/OFRP_tensor_g3).
- No logs = no fix.

</details>
