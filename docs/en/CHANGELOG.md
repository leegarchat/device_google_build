# Changelog

**English** | [Русский](../ru/CHANGELOG.md)

> One section per build, newest on top. A new build = new section here,
> old ones stay untouched.

## 12.3 — 15/10/2026

- Base synced to the latest EvolutionX source. October Android security patch.
  Vendor & boot security patches unchanged.
- Kernel: WildKSU release 20 → 21. Manager: reSukiSU RC1 → RC3.
- **reSukiSU manager auto-install** (KSU kernel builds only):
  the manager APK ships inside the system image as an inert file and is
  installed once as a regular user app after the first boot / first boot
  after update. A system setting remembers the handled version: same
  version → skip, newer on device → keep it (no downgrade), older or
  missing → install / update. Failed install retries next boot.
  A deliberate user uninstall is respected — no reinstall.
- **PEP: new LSPlant engine** (was Pine):
  - Own native backend instead of the old Pine binaries — faster and cleaner.
  - Hook engine starts in milliseconds instead of seconds.
  - Plays nice with other hook tools: if one is already injected, PEP uses it
    instead of injecting twice.
  - Old settings keep working — they are read automatically, new ones save
    in the new format.
  - Per-app blocks are respected: a blocked app stays unhooked after reboot.
  - Safe mode at injection: broken state disables hooks instead of crashing.
- **PEP: shade zoom reworked** (SystemUI hooks 2.2.22):
  - Zoom centered at 0: plus deepens shrink, minus reverses to enlarge.
  - Works even with blur at 0. No jump on entry, no flicker at edges.
  - Same smooth feel at 60 and 120 Hz.
  - Shade date opens Calendar again; AOD icon colors back.
- **PEP: addons update over the air** — all built-in modules rebuilt,
  version manifests + hosted files, update check inside the manager.
- **PEP: translations complete** — full string set in all languages.
- **PEP: patches refreshed** to the October source tree (part of the old
  patches upstream absorbed — retired).

## 12.2 — 27/09/2026

- Base synced to EvolutionX 12.2. September security patch.
- Kernel: WildKSU + ReSukisu (was KSU-Next).
- OrangeFox R12 recovery inside.
- SystemUI tweaks apply without restart (restart still recommended).
- Status-bar app icons: more stable, instant.
- Minor hook + PEP fixes.

## 12.1 — 05/09/2026

- Base synced to EvolutionX 12.1.
- **AutoLock (Media Sleep Guard)** — timer lock even during playback,
  wake-lock trigger mode, media auto-pause, 10 sec–60 min, live countdown.
- Now Playing fixed, fully working.

## 12.1 — 29/08/2026

- Base synced. August security patch (system + vendor + boot).
- **Auto-HBM rewritten** — stable, slider lock while active.
- **Silent theme install** — custom animations/shapes install with no taps,
  no Play Protect warnings.
- **DT2W reworked** — own SystemUI process, stable taps while locked.
- **Rotation animations** — built-ins + custom editor.
- **Launcher hooks** — stable Live-Tile removal, no more crashes.

## test — 20/08/2026 (shiba)

- Thermal engine built from source (was stock prebuilt) — bootloop fixed.
- Third-party app transition animations fixed.
- HBM sensor offsets fixed.
