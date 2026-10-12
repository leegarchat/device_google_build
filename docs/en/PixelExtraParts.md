# PixelExtraParts — User Guide

One app — **Pixel Extra Parts** — holds the extras of this ROM.
No root. No extra modules. It just works.

Find it here:

- Drawer → **Pixel Extra Parts**
- Settings → **Pixel Extra Parts** row
- Quick Settings tiles — long-press opens its page

<details>
<summary>📱 Main screen</summary>

Search on top. Groups: **System**, **Misc**, **SystemUI**, **Camera**.
Floating button: add tile, restart Launcher / SystemUI, reboot.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/home/pic1.png)
![](../pic/PEP/home/pic2.png)
![](../pic/PEP/home/pic3.png)
![](../pic/PEP/home/pic4.png)

</details>
</details>

---

## Display

`Pixel Extra Parts → Display`

<details>
<summary>📂 Display hub — 4 sections</summary>

Saturation, sun boost, double tap to wake, auto lock.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/display/pic1.png)

</details>
</details>

<details>
<summary>🎨 Saturation — screen color strength</summary>

Makes colors pale or vivid. Applies at once, with photo preview.

- **Use custom saturation** — master. Off = normal.
- **Level — 0–200%, normal 100%.**
- **Tile** — quick on / off from Quick Settings.

If the system color mode overrides it, just re-apply.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/display/pic2.png)

</details>
</details>

<details>
<summary>☀️ Sun boost — max brightness in light</summary>

Pushes the screen to max in bright sun, then returns yours.
Two modes, only one at a time: **Auto** (by sensor) and **Permanent** (always max).

- **Lock brightness** — holds max, blocks the slider.
- **Live card** — current light, threshold progress, chip temperature.
- **Light threshold — 100 to 60 000 lux.** Above = turn on.
- **Turn-on / turn-off delays — 0 to 10 sec.** Ignores passing shadows.
- **Smooth rise — on/off + duration 100 ms to 5 sec.**
- **Sensor check — 30 ms to 10 sec.**
- **Safety: max time 10 sec to 33 min, cooldown after it, chip limit 30–80°.**
  Overtime or overheat switches boost off with a toast, then restores.

Live notification with Disable + Lock buttons. Tiles: **AutoHBM**, **HBM**.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/display/pic3.png)
![](../pic/PEP/display/pic4.png)

</details>
</details>

<details>
<summary>👆 Double tap to wake</summary>

Wakes the sleeping screen by taps. Small delay is normal.

- **On / off.**
- **Taps — 1 to 3.**
- **Max pause between taps — 100 ms to 2 sec.**
- **Same-spot check** — second tap must land near the first.
- **Max distance — 10 to 500 dp**, with a visual circle.
  The circle shows the allowed distance, not a spot to tap.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/display/pic5.png)
![](../pic/PEP/display/pic6.png)
![](../pic/PEP/display/pic7.png)

</details>
</details>

<details>
<summary>🔒 Auto lock when idle</summary>

Locks the screen when you stop touching it. Made for videos.

- **On / off.**
- **Only when needed** — count only while an app keeps the screen awake.
- **Pause media** — pause video / music before locking.
- **Timeout — 10 sec to 1 hour.** Shown as sec / min / hr.

Any touch or button resets the timer. Live countdown notification.
Tile cycles Off → On → Smart.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/display/pic8.png)

</details>
</details>

---

## Icons

`Pixel Extra Parts → App Icons`

<details>
<summary>📂 Icons hub</summary>

Top group **Advanced**: icon shape, Settings icons look, advanced rules.
Then **Icon packs**, then **All applications** with system / hidden filters and search.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/appIcon/pic1.png)
![](../pic/PEP/appIcon/pic8.png)

</details>
</details>

<details>
<summary>🎭 Icon packs</summary>

- **Replace icons** — everywhere + launcher. **Launcher only** — launcher alone.
- **Per pack** — supported / icons / applied counters, status.
- **Apply all** — whole pack, modes: all, system only, your apps only, installed only.
- **Apply some** — checkboxes → selected only.
- **View icons** — searchable pack grid.
- **Update / Undo pack / Clear all** — maintenance.
- **Per app** — restore stock, import your picture, pick from a pack,
  own shape overrides for Settings / Notifications / Launcher with Save / Use global.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/appIcon/pic2.png)
![](../pic/PEP/appIcon/pic3.png)
![](../pic/PEP/appIcon/pic4.png)
![](../pic/PEP/appIcon/pic5.png)
![](../pic/PEP/appIcon/pic6.png)
![](../pic/PEP/appIcon/pic7.png)

</details>
</details>

<details>
<summary>⚙️ Shape, size, color — advanced</summary>

For **system**, **notifications**, **launcher** separately:

- **Stretch to shape** — clean cut, no white backing.
- **Remove shape** — raw icon.
- **Size — 0 to 200%, fit around 72%.** 0% hides, 200% overfills.
- **Background fill** — Off / fixed color / auto color from icon.
- **Icon tint** — Off / fixed / auto.
- **All Apps rules** — Home = Drawer, Drawer = Home,
  single-color icons in drawer and suggestions, ignore per-app shapes.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/appIcon/pic9.png)
![](../pic/PEP/appIcon/pic10.png)
![](../pic/PEP/appIcon/pic11.png)
![](../pic/PEP/appIcon/pic12.png)

</details>
</details>

<details>
<summary>🏠 Settings icons look</summary>

**Use global shape — on/off.** Keeps Settings colors,
replaces corner styles with the global mask.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/appIcon/pic13.png)

</details>
</details>

<details>
<summary>✨ Own shape — builder and presets</summary>

- **Builder** — name it, pick Squircle / Polygon / Flower.
- Roundness, sides, inset, wave, rotation, width / height, X / Y shift.
  Live preview, on-device install. Import from SVG / vector / pasted shape.
- **Presets** — Default (active system one), installed overlays,
  built-in set: iOS, rounded, squircle, square, hexagon, teardrop and more.

Restart Launcher / SystemUI after applying so caches refresh.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/appIcon/pic14.png)
![](../pic/PEP/appIcon/pic15.png)
![](../pic/PEP/appIcon/pic16.png)

</details>
</details>

---

## System

`Pixel Extra Parts → SystemUI Settings`

<details>
<summary>📂 System hub + one-tap logs</summary>

- **Module pages** — Lock screen, Shade and QS, Notification icons.
- **Background logging** — Start / Stop + live status.
  System log, kernel log, crash log separately.
  Files go to `PixelExtraPartsLogs/<date>/`. Attach the folder to bug reports.
- Then: Text Magnifier, Activity Transitions, Rotation Animation.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic1.png)
![](../pic/PEP/SystemUI/pic2.png)

</details>
</details>

<details>
<summary>⚡ Charging numbers on lockscreen</summary>

Live measurements under the clock.

- **Show data** — master (same as the tile).
- **Power / Voltage / Current / Temperature / Percent** — each separately.
- **Keep stock text** — Fast / Slow next to numbers.
- **Own symbol** — editable, e.g. ⚡.
- **Refresh — 100 ms to 5 sec. Smoothing** averages jumps.
- **Tile** binds the same switch.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic3.png)
![](../pic/PEP/SystemUI/pic4.png)

</details>
</details>

<details>
<summary>🔆 Shade, player, calendar</summary>

- **Shade master — on/off.** Off = stock look back at once.
- **Date opens Calendar** instead of Clock.
- **Player size — Off / Compact / In header / Mini.**
- **Player transparency — 0 to 1.**
- **Hide player** in Quick Settings / notifications / lockscreen — separately.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic5.png)
![](../pic/PEP/SystemUI/pic6.png)

</details>
</details>

<details>
<summary>🌫 Shade background and dim</summary>

Live, no restart.

- **Blur — 0 to 400%.** 100% = normal.
- **Zoom — −1000 to +1000%.** 0 = normal. Works even with blur at 0.
- **Zoom on/off, follow speed 0 to 1000** (0 = direct).
- **Dim of notifications zone / main zone — auto (−1) to 100%.**
- **Dim tint** — switch + color (skipped on lockscreen / AOD).

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic6.png)
![](../pic/PEP/SystemUI/pic7.png)

</details>
</details>

<details>
<summary>🔔 App icons in bar and always-on</summary>

- **Status bar: real icons + optional single-color.**
- **Always-on: real icons + single-color + full-color mode.**

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic8.png)

</details>
</details>

<details>
<summary>🔍 Text loupe</summary>

- **Custom zoom — on/off.**
- **Zoom 0.5–4×, window size 0.5–3×.**
- **Shape — normal / square / circle.**
- **Vertical shift — −200 to +200 dp.**
- Sample text + Preview.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic9.png)

</details>
</details>

<details>
<summary>🎬 Open / close animations</summary>

- Status card: current open / close + **Off** reset.
- **No animation** mode with Apply Both / Open / Close.
- **Ready styles** — Slide, Card Stack, Train, iOS, Fade, Zoom, Modal, Depth, Pivot, each in 4 directions. Each with previews and the same three buttons.
- **Your themes** — apply / delete.
- **Create theme** — name + enter / exit files (or pasted code) → Build & install on the phone.
- **Constructor** — move, scale, transparency, rotation, pivot, timing, smoothness, live preview, Build / Show code.
- **No back-gesture animation** switch. Tile toggles animations.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic10.png)
![](../pic/PEP/SystemUI/pic11.png)
![](../pic/PEP/SystemUI/pic12.png)
![](../pic/PEP/SystemUI/pic13.png)
![](../pic/PEP/SystemUI/pic14.png)

</details>
</details>

<details>
<summary>🔄 Rotation animation</summary>

Same idea for screen rotation.

- Status + Reset to default.
- Ready styles: Windows Phone, Windows 10/11, Cube, Zoom, Slide, Flip, Fade, Bounce — preview + Apply.
- Your themes — Apply / Delete.
- Import — name + exit / enter files → Build & install.
- Constructor — Exit / Enter tabs, same editors, phone-shaped preview.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SystemUI/pic15.png)
![](../pic/PEP/SystemUI/pic16.png)
![](../pic/PEP/SystemUI/pic17.png)
![](../pic/PEP/SystemUI/pic18.png)
![](../pic/PEP/SystemUI/pic19.png)
![](../pic/PEP/SystemUI/pic20.png)

</details>
</details>

<details>
<summary>🌙 Night screen</summary>

- **Blackout** — full black after quiet time. Delay 1 sec to 10 min, fade up to 10 sec.
- **Pixel mask** — fewer lit pixels (10–100%) + shifting pattern against burn-in.
- **Sleep dimming** — extra darkness strength.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/AmbientAOD/pic1.png)
![](../pic/PEP/AmbientAOD/pic2.png)

</details>
</details>

<details>
<summary>📷 Camera flash</summary>

Extra always-on flashlight item in the Google Camera photo flash menu. On / off.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Gcam/pic1.png)

</details>
</details>

<details>
<summary>📶 SIM and network</summary>

- **One-switch preset** — VoLTE + Wi-Fi calling + video + extras together.
- **Clear carrier override** button.
- **Voice services** — VoLTE, Wi-Fi calling, video, cross-SIM, extras — each separately.
- **Network** — VoNR, 5G availability, 5G thresholds — active subscriptions only.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/IMS/pic1.png)
![](../pic/PEP/IMS/pic2.png)

</details>
</details>

<details>
<summary>⚙️ Settings row look</summary>

- **Show in Settings — on/off.**
- **Position** — lower number = higher in the list.
- **Colored icon — on/off. Background / glyph colors** — Auto or custom hex.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/SettingsHome/pic1.png)
![](../pic/PEP/SettingsHome/pic2.png)

</details>
</details>

---

## Launcher

<details>
<summary>📂 Launcher hub</summary>

Home screen, Dock and search, App drawer, Gesture bar, Recents, Quick Settings tiles.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic1.png)

</details>
</details>

<details>
<summary>🏠 Home grid + sleep tap</summary>

- **Custom grid — on/off. Columns 3–10, rows 4–12.**
- **Icon size 50–160%.** 100% = stock.
- **Labels — normal / 2 lines / running line / hidden.**
- **Double tap empty space = sleep.** Only Pixel Launcher, not on widgets.
- **Tap window 100–800 ms.**

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic2.png)
![](../pic/PEP/PixelLauncher/pic3.png)

</details>
</details>

<details>
<summary>🔎 Dock and search</summary>

- **Custom dock — on/off.**
- **Fast local search** — apps and contacts without Google App redirect.
- **Icons in dock 0–10** (0 = default), dock icon size.
- **Hide dock, hide search.**
- **Offsets** — home bottom, dock, search, page dots X / Y.

Also: **No Google Feed** (−1 screen), **no top widget** (frees the slot).

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic4.png)
![](../pic/PEP/PixelLauncher/pic5.png)

</details>
</details>

<details>
<summary>🗂 Drawer</summary>

- **Custom drawer — on/off. Columns 3–10.**
- **Row height, icon size, label mode.**
- **Suggestions row** — hide, icon size, label mode.
- **Search results** — icon size, label mode.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic6.png)
![](../pic/PEP/PixelLauncher/pic7.png)

</details>
</details>

<details>
<summary>➖ Bottom bar</summary>

- **Tuning — on/off. Width 8–100%, height 1–16 dp, X / Y shift.**
- **Bottom gaps** — reserved area and swipe strip, 0–96 dp each.
- **Auto-hide** at home / in apps / on lockscreen + delays up to 10 sec.
- **Let apps use the bottom** — swipe still works.
- **Transparency 0–100%, fade 20 ms–1.5 sec, custom color.**

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic8.png)
![](../pic/PEP/PixelLauncher/pic9.png)
![](../pic/PEP/PixelLauncher/pic10.png)
![](../pic/PEP/PixelLauncher/pic11.png)

</details>
</details>

<details>
<summary>📑 Recent apps</summary>

- **Carousel** — spacing (−200 to +200), edge scale (0.5–1.5),
  edge transparency (0.1–1), card blur (0–80), tint color + strength,
  icon shifts, static previews instead of live, global scale (50–150%).
- **Clear-all** — on/off, hide Screenshot / Select row,
  Bottom / Screenshot / Select mode, bottom margin.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic12.png)
![](../pic/PEP/PixelLauncher/pic13.png)
![](../pic/PEP/PixelLauncher/pic14.png)
![](../pic/PEP/PixelLauncher/pic15.png)
![](../pic/PEP/PixelLauncher/pic16.png)

</details>
</details>

<details>
<summary>🧷 Launcher tiles + hidden apps</summary>

- **Tiles page** — fixed (e.g. double-tap sleep: Not added → Bind)
  and custom tiles with Bind.
- **Hidden apps** — checkboxes, system filter, search.
  Restart launcher to apply.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/PixelLauncher/pic17.png)
![](../pic/PEP/HideApp/pic1.png)

</details>
</details>

---

## Scroll effects

`Scroll Physics`

<details>
<summary>🌊 Main — profiles and spring</summary>

- Master **System Integration — on/off.**
- **Playground** — test cards.
- **Profiles** — Save / Import / Export / Online profiles in one tap
  (iOS Rubber Band, Elastic, Snap Back, Wave, Zoom Pulse, Bouncy Ball and more).
- **Spring** — pull (0.1–3), stiffness (10–1000), damping (0.1–2),
  fling (0.1–3), resistance curve (1–8), speed (1–300%).

Moving any slider makes your setup custom until you save it.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Scroll/pic1.png)
![](../pic/PEP/Scroll/pic2.png)
![](../pic/PEP/Scroll/pic3.png)
![](../pic/PEP/Scroll/pic10.png)

</details>
</details>

<details>
<summary>📐 Look — deform groups</summary>

Vertical / Zoom / Horizontal — each **Off / shrink / stretch**.
Then strength, limit, pivot points. Greyed out while Off.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Scroll/pic4.png)
![](../pic/PEP/Scroll/pic5.png)
![](../pic/PEP/Scroll/pic6.png)

</details>
</details>

<details>
<summary>🔧 Fine + per-app</summary>

- **Fine** — input smoothing, cutoffs, pull / fling smoothing,
  Compose divider, smart pivot.
- **Compose smoothing** — auto fix for modern lists
  (behavior / hybrid / stack modes, window, correction).
- **Per app** — Add Application: own multiplier (0–6),
  smoothing, or fully off. Reset button.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Scroll/pic7.png)
![](../pic/PEP/Scroll/pic8.png)
![](../pic/PEP/Scroll/pic9.png)

</details>
</details>

---

## Heat — instant, no reboot

Switches **in seconds on the running phone**.
Old screens may still offer a reboot — just press OK, it already works.

<details>
<summary>🌡 Global + per-game + tile queue</summary>

- **Global profile** — default for everything. Stock + Battery / Processor combos
  (Soft +5°, Medium +9°, Hard +15°, Off = extreme).
- **Per app** — own profile per game, or Follow global.
  The phone watches the open app every second and swaps itself.
- **Tile queue (up to 5)** — tap the Heat tile to cycle favorites.
- Red cards = hot modes. Short sessions only.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Thermal/pic1.png)
![](../pic/PEP/Thermal/pic2.png)
![](../pic/PEP/Thermal/pic3.png)

</details>
</details>

<details>
<summary>🧪 Profile editor</summary>

- Copy a stock profile, rename, tune charging / processor limits.
- Search over hundreds of fields, hints per field.
- **Save / Save and apply**, import / export JSON.
- Stock configs are locked — clone before editing.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Thermal/pic4.png)
![](../pic/PEP/Thermal/pic5.png)

</details>
</details>

---

## Modules

<details>
<summary>🧩 Modules list</summary>

- **Built-in** (from firmware) + **imported** `.jar` files.
- Each: on / off, where it works, its settings and pages,
  import / export, update check, delete.
- **Where it works** — Default / Custom / Merge targets + app picker.
- Crash protection: repeated crashes pause modules in safe mode.
- **Module tiles** — own Quick Settings toggles. Long-press opens the page.

<details>
<summary>Screenshots</summary>

![](../pic/PEP/Addons/pic1.png)
![](../pic/PEP/Addons/pic2.png)
![](../pic/PEP/Addons/pic3.png)
![](../pic/PEP/Addons/pic4.png)
![](../pic/PEP/Addons/pic5.png)
![](../pic/PEP/Addons/pic6.png)

</details>
</details>

---

## Tiles

Saturation, sun boost, permanent boost, auto lock,
double tap, animations, scroll, heat queue,
charging info, loupe, logs, hub, module tiles.
Long-press any tile → its page.

## Quick fixes

<details>
<summary>Switches do nothing (icons, launcher)</summary>
That build misses the system part. Patches + rebuild fix it.
</details>

<details>
<summary>Launcher looks broken after grid / icons</summary>
Floating button → Restart Launcher.
</details>

<details>
<summary>Shade looks wrong</summary>
Shade master off — stock look is back at once.
</details>

<details>
<summary>Boost switches off by itself</summary>
Safety: time cap or chip temperature with cooldown.
</details>

<details>
<summary>Modules gone / safe mode</summary>
Three SystemUI crashes in 3 minutes pause modules.
Disable the suspect, exit safe mode.
</details>
