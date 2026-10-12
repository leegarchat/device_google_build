# PixelExtraParts — User Guide

One app — **Pixel Extra Parts** — holds the extras of this ROM.
No root. No extra modules. It just works.

Find it here:

- Drawer → **Pixel Extra Parts**
- Settings → **Pixel Extra Parts** row
- Quick Settings tiles — long-press opens its page

<details>
<summary>📱 Main screen — what you see first</summary>

Search on top, groups below: **System**, **Misc**, **SystemUI**, **Camera**.
Floating button: tile add, Launcher / SystemUI restart, reboot.

![](../pic/PEP/home/pic1.png)
![](../pic/PEP/home/pic2.png)
![](../pic/PEP/home/pic3.png)

The round menu (last shot): **Show on desktop, Add app tile,
Restart Launcher, Restart SystemUI, Reboot System, Close**.

![](../pic/PEP/home/pic4.png)
</details>

---

## Display

`Pixel Extra Parts → Display → Screen`

<details>
<summary>📂 Display hub (4 rows)</summary>

- Saturation — color strength
- AutoHBM — boost in sun
- Double Tap to Wake
- Auto lock

![](../pic/PEP/display/pic1.png)
</details>

<details>
<summary>🎨 Saturation</summary>

- Preview photo with arrows, dots, **100%** label.
- **Use custom saturation** — off in the shot. Off = normal.
- **Saturation level — 200%** greyed out while the switch is off.
- **+ Add Saturation tile** button.
- Note below: system color mode can override the value.

![](../pic/PEP/display/pic2.png)
</details>

<details>
<summary>☀️ Sun boost (AutoHBM)</summary>

Top card, live numbers from the shot:

- **Current light level — Monitoring — 14**
- `Threshold: 4289 lx • Brightness: 1052/3827 • Tensor G3: 35.0°C`
- **Lux check interval — 250 ms**

Switches:

- **Enable automatic HBM — ON**
- **Permanent HBM — OFF** (max forever, ignores sensor)
- **Lock brightness — ON**
- **Light threshold — 4289 lx**
- **Enable delay — 0 s**
- **Disable delay — 1 s**
- **Smooth rise — ON, Ramp 800 ms**
- **Max time — 1396 s, Cooldown 60 s**
- **Chip limit — 80°C**

Overtime or overheat switches boost off with a toast, then restores.
Notification shows lux / peak / lock with Disable + Lock buttons.
Tiles: **AutoHBM**, **HBM**.

![](../pic/PEP/display/pic3.png)
![](../pic/PEP/display/pic4.png)
</details>

<details>
<summary>👆 Double tap to wake</summary>

- **Enable DT2W — ON**
- **Tap count — 2**
- **Tap timeout — 483 ms**
- **Coordinate check — ON**
- **Allowed second-tap area** — preview with phone outline.
  Text says it is only a preview, not a spot to tap.
- **Max distance — 240 dp** (second shot: 227 dp).

![](../pic/PEP/display/pic5.png)
![](../pic/PEP/display/pic6.png)
![](../pic/PEP/display/pic7.png)
</details>

<details>
<summary>🔒 Auto lock</summary>

- **Auto lock — ON** (for videos / apps that keep screen on)
- **Only when needed — ON**
- **Pause media — ON**
- **Inactivity timeout — 543 sec / 9 min 3 sec**
- Help: time without touch before lock.

Any touch or button resets the timer.
Tile cycles Off → On → Smart.

![](../pic/PEP/display/pic8.png)
</details>

---

## Icons

`Pixel Extra Parts → App Icons`

<details>
<summary>📂 Icons hub</summary>

Top: **Advanced** group.

- **Icon shape** — presets and custom shapes.
- **Settings icon style override** — global mask.
- **Advanced icon settings** — shape, tint, launcher rules.

Then **Icon packs (1 pack)**, then **All applications (114 / 628)**.

![](../pic/PEP/appIcon/pic1.png)
![](../pic/PEP/appIcon/pic8.png)
</details>

<details>
<summary>🎭 Packs and app list</summary>

- Pack card: name, package, **Not applied**, *Supported / Icons / Applied*.
- **Apply all, Apply partially, View set, Undo all.**
- **Show system apps — ON, Show hidden apps — ON/OFF.**
- Search by name or package.
- Rows show **Icon pack not applied**.
- With system apps on: system entries appear (e.g. 3 Button Navigation Bar).

![](../pic/PEP/appIcon/pic2.png)
![](../pic/PEP/appIcon/pic3.png)
</details>

<details>
<summary>📱 Per-app card (Chrome)</summary>

- **Current custom icon — Icon pack not applied.**
- **Import custom icon, Choose from icon pack.**
- **Individual shape settings** — overrides for this app only.
- Groups: **Settings, Notifications, Pixel Launcher.**
- Each: **Stretch to shape — OFF, Remove shape — OFF, Shape scale — 72.00%.**
- Hint: *0% hides, 72% is fit, 200% overfills.*
- Bottom: **Use global / Save settings.**
- **Available icons** — per-pack rows with **Apply**.

![](../pic/PEP/appIcon/pic4.png)
![](../pic/PEP/appIcon/pic5.png)
![](../pic/PEP/appIcon/pic6.png)
</details>

<details>
<summary>🔍 Pick from pack</summary>

Dialog **Choose from icon pack → Chrome**.
Search, **Detected alternatives**, **All pack icons**, per-row **Apply**, **Close**.

![](../pic/PEP/appIcon/pic7.png)
</details>

<details>
<summary>⚙️ Advanced icon settings</summary>

- **Core toggles** — Enable icon system — ON, Apply in Pixel Launcher — ON.
- **Shape and scale** — Stretch / Remove for system, notifications, launcher — all OFF in shots, scales **72.00%**.
- **Tinting** — Background tinting **Off**, Background color `#00000000` + Pick (disabled), Icon tinting **Off**, Icon color `#FFFFFFFF` + Pick (disabled).
- **All Apps and per-app shapes** — Workspace matches All Apps OFF, Ignore per-app shapes OFF, All Apps follows workspace OFF, Themed icons in All Apps OFF, Themed in suggestions OFF.

![](../pic/PEP/appIcon/pic9.png)
![](../pic/PEP/appIcon/pic10.png)
![](../pic/PEP/appIcon/pic11.png)
![](../pic/PEP/appIcon/pic12.png)
</details>

<details>
<summary>🏠 Settings icons look</summary>

**Use global Settings icon shape — ON.**
Keeps Settings colors, replaces corner styles with the global mask.

![](../pic/PEP/appIcon/pic13.png)
</details>

<details>
<summary>✨ Custom shape builder</summary>

- Preview + **Shape name — PixelParts custom** + **Build**.
- Tabs **Squircle / Polygon / Flower**.
- **Roundness 4.50, Inset 0.00, Rotation 0.00, Width 1.00, Height 1.00, X 0.00, Y 0.00.**
- **Import + Build imported.**

![](../pic/PEP/appIcon/pic14.png)
</details>

<details>
<summary>📦 Shape presets</summary>

- **Default — System default — Active.**
- Installed overlays: **Arch, Leaf, Meow…** with **Apply**.
- Built-in presets with **Build**: Rounded rectangle, Squircle, Square, Hexagon, Teardrop, Tapered rectangle, Pebble…

![](../pic/PEP/appIcon/pic15.png)
![](../pic/PEP/appIcon/pic16.png)
</details>

---

## System

`Pixel Extra Parts → SystemUI Settings`

<details>
<summary>📂 System hub + logs</summary>

- **Module Settings** — Lock screen, Shade and QS, Notification icons.
- **Background Logging** — **Log in background — Start, Process is stopped.**
- **Log logcat — ON, Log dmesg — ON, Catch app crashes — OFF.**
- Logs go to `/sdcard/PixelExtraPartsLogs/Date`.
- Then: **Text Magnifier, Activity Transitions, Rotation Animation.**

![](../pic/PEP/SystemUI/pic1.png)
![](../pic/PEP/SystemUI/pic2.png)
</details>

<details>
<summary>⚡ Charging on lockscreen</summary>

Screen **Lock screen → Charging info**.

- **Show charging data — ON.**
- **Refresh interval — 1000 ms.**
- **Average readings — OFF.**
- **Standard string — ON, Custom symbol — ON, Symbol — ⚡.**
- **Power — ON, Voltage — ON, Current — ON, Temperature — ON, Percent — OFF.**
- **Quick Settings tiles — Charging info tile — Bind tile.**

![](../pic/PEP/SystemUI/pic3.png)
![](../pic/PEP/SystemUI/pic4.png)
</details>

<details>
<summary>🔆 Shade and player</summary>

Screen **Shade and QS**.

- **Shade tweaks — ON** (off = stock look back).
- **QS header — Date opens Calendar — ON.**
- **QS media player** — Background opacity **1.00**, Compact mode **Mini**.
- **Hide in QS — OFF, Hide in notifications — OFF, Hide on lock screen — OFF.**

![](../pic/PEP/SystemUI/pic5.png)
![](../pic/PEP/SystemUI/pic6.png)
</details>

<details>
<summary>🌫 Shade surface and dim</summary>

- **Shade surface** — live, no restart.
- **Blur intensity — 100%.**
- **Zoom intensity — −689%.**
- **Enable zoom — OFF** (off = sharp surface).
- **Zoom gravity — 0** (0 = direct tracking).
- **Scrim** — Notification **−1%**, Main **−1%** (−1 = system value).
- **Tint notification / main — OFF**, colors **0** + Pick (disabled).

![](../pic/PEP/SystemUI/pic6.png)
![](../pic/PEP/SystemUI/pic7.png)
</details>

<details>
<summary>🔔 Status bar and always-on icons</summary>

Screen **Notification icons**.

- **Status bar — Use app icons — ON, Monochrome — OFF.**
- **AOD — Use app icons — ON, Monochrome — ON, Legacy full color — OFF.**

![](../pic/PEP/SystemUI/pic8.png)
</details>

<details>
<summary>🔍 Text loupe</summary>

Screen **Text Magnifier**.

- **Custom zoom — OFF** (so the rest is greyed out).
- **Zoom 1.25x, Window 1.00x.**
- **Window shape — Default** (Square, Circle below).
- **Vertical offset — 0dp.**
- Sample text field + **Preview**.

![](../pic/PEP/SystemUI/pic9.png)
</details>

<details>
<summary>🎬 Open / close animations</summary>

Screen **Activity Transitions**.

- **Disable Predictive Back — ON.**
- Status: **Current open: Depth — Bottom / Current close: Depth — Bottom**, pill **Disabled**.
- **Built-in Animations — No Animation** with Apply Both / Open / Close.
- Collapsed rows: Slide Right / Left / Top / Bottom…
- Expanded **Slide — Right**: phone previews Open / Close, same three buttons.
- **Installed Themes — No animation themes installed.**
- **Create Animation Theme** — Style name, **File / XML Text** tabs,
  Open Enter / Open Exit / Close Enter / Close Exit file rows,
  **Compile & Install** (greyed out until files picked).

![](../pic/PEP/SystemUI/pic10.png)
![](../pic/PEP/SystemUI/pic11.png)
![](../pic/PEP/SystemUI/pic12.png)
</details>

<details>
<summary>🧱 Animation constructor</summary>

Tabs **Open Enter / Open Exit / Close Enter / Close…**.

- **Translate** fromX / toX / fromY / toY.
- **Scale** fromX / toX / fromY / toY (1.00 in shot).
- **Alpha** from / to (1.00).
- **Rotate**, **Timing duration 350 ms / offset 0 ms**, **Interpolator Linear**.
- **Preview** with two phone mocks.
- **Build Theme, Show XML.**

![](../pic/PEP/SystemUI/pic13.png)
![](../pic/PEP/SystemUI/pic14.png)
</details>

<details>
<summary>🔄 Rotation styles</summary>

Screen **Rotation Animation**.

- Status: **Current: Windows 10/11**, **Reset to default**.
- **Built-in Styles** — Windows Phone, **Windows 10/11 — Active**,
  Cube, Zoom, Slide, Flip, Fade (+ Bounce below).
- Expanded style shows preview + **Active** button.
- **Custom Themes — No custom themes installed.**
- **Import Theme** — Style name, Exit / Enter files (**No file selected**),
  **Build & Install** (greyed out).

![](../pic/PEP/SystemUI/pic15.png)
![](../pic/PEP/SystemUI/pic16.png)
![](../pic/PEP/SystemUI/pic17.png)
</details>

<details>
<summary>🧱 Rotation constructor</summary>

Tabs **Exit / Enter**.

- **Translate** fromX / toX / fromY / toY (0 in shot).
- **Scale** 1.00 everywhere.
- **Alpha from 1.00 to 0.00.**
- **Rotate from 0° to −90°.**
- **Pivot X 50 / Y 50.**
- **Timing duration 320 ms / offset 0 ms, Interpolator Linear.**
- **Rotation preview** phone mock.
- **Build Rotation Theme, Show XML.**

![](../pic/PEP/SystemUI/pic18.png)
![](../pic/PEP/SystemUI/pic19.png)
![](../pic/PEP/SystemUI/pic20.png)
</details>

<details>
<summary>🌙 Night screen (Ambient Extend)</summary>

Screen **Ambient Extend**.

- **AOD blackout — ON, Delay 60 s, Fade 1200 ms.**
  Turns always-on off after quiet time.
- **Smart Pixels — ON, Disabled pixels 72%, Mask shifting ON.**
  Fewer lit pixels, pattern moves against burn-in.
- **Doze dimming — OFF, strength 26%.**
  Extra darkness layer in sleep mode.

![](../pic/PEP/AmbientAOD/pic1.png)
![](../pic/PEP/AmbientAOD/pic2.png)
</details>

<details>
<summary>📷 Camera flash</summary>

Screen **GCam Photo Torch → Photo flash controls**.

- **Enable Torch — ON.**
  Shows the Torch option in Google Camera photo flash menu.

![](../pic/PEP/Gcam/pic1.png)
</details>

<details>
<summary>📶 SIM / network (IMS Carrier Config)</summary>

Screen **IMS Carrier Config**.

- Banner **System API path**.
- **Voice stack preset — ON** (VoLTE + Wi-Fi calling + video + UT together).
- **Clear carrier override** button.
- **Voice services** — VoLTE, Wi-Fi calling, Video calling, Cross-SIM, UT — all ON in shots.
- **Network services** — VoNR, 5G NR availability, 5G thresholds — ON.

![](../pic/PEP/IMS/pic1.png)
![](../pic/PEP/IMS/pic2.png)
</details>

<details>
<summary>⚙️ Settings entry look</summary>

Screen **Settings Homepage Item**.

- **Visibility and order** — Show Pixel Extra Parts — ON.
- **Settings position — −139** (lower = higher in the list).
- **Icon style** — Colored icon — OFF.
- **Icon background — Auto**, Custom background `#67DDF7` + Pick (disabled).
- **Glyph color — Auto**, Custom glyph `#0B3D4F` + Pick (disabled).

![](../pic/PEP/SettingsHome/pic1.png)
![](../pic/PEP/SettingsHome/pic2.png)
</details>

---

## Launcher

<details>
<summary>📂 Launcher hub</summary>

Screen **Pixel Launcher Settings → System**.

- Home screen
- Dock and search
- App drawer
- Gesture bar
- Recents
- Quick Settings tiles

![](../pic/PEP/PixelLauncher/pic1.png)
</details>

<details>
<summary>🏠 Home grid + sleep tap</summary>

Screen **Home screen**.

- **Home grid** — Modify switch **OFF** in shot.
- **Columns 5, Rows 6, Icon size 100%, Labels Default.**
- **Sleep gesture** — Double tap to sleep **OFF**,
  Double-tap window **250 ms**.

![](../pic/PEP/PixelLauncher/pic2.png)
![](../pic/PEP/PixelLauncher/pic3.png)
</details>

<details>
<summary>🔎 Dock and search</summary>

Screen **Dock and search**.

- **Modify dock and search — OFF.**
- **Use native search — ON** (only the search field is redirected).
- **Dock icons 0** (0 = launcher default), **Dock icon size 100%.**
- **Hide dock — OFF, Hide search — OFF.**
- **Offsets** — Home bottom **−45 dp**, Dock **0**, Search **0**,
  Dots vertical **0**, Dots horizontal **0**.

![](../pic/PEP/PixelLauncher/pic4.png)
![](../pic/PEP/PixelLauncher/pic5.png)
</details>

<details>
<summary>🗂 Drawer</summary>

Screen **App drawer**.

- **Modify app drawer — OFF.**
- **Columns 5, Row height 100%, Icon size 100%, Labels Default.**
- **Suggestions** — Hide row OFF, Suggestion icon 100%, Suggestion labels Default.
- **Search results** — Search icon 100%, Search labels Default.

![](../pic/PEP/PixelLauncher/pic6.png)
![](../pic/PEP/PixelLauncher/pic7.png)
</details>

<details>
<summary>➖ Bottom bar geometry</summary>

Screen **Gesture bar → Handle geometry**.

- **Enable tuning — ON.**
- **Width 28%, Height 4 dp, X 0, Y 0.**
- **Reserved area 24 dp, System gesture area 24 dp.**

![](../pic/PEP/PixelLauncher/pic8.png)
![](../pic/PEP/PixelLauncher/pic9.png)
</details>

<details>
<summary>👻 Bottom bar hiding + look</summary>

- **Auto-hide** — Hide on launcher **ON** (delay 3000 ms),
  Hide in apps **ON** (delay 3000 ms),
  Hide on lock screen **ON**, Remove reserved area **OFF**.
- **Appearance** — Opacity **58%**, Fade-in **220 ms**, Fade-out **220 ms**,
  Set color **OFF**, Bar color **#FFFFFF** + Pick.

![](../pic/PEP/PixelLauncher/pic10.png)
![](../pic/PEP/PixelLauncher/pic11.png)
</details>

<details>
<summary>📑 Recent apps hub</summary>

Screen **Recents → System**.

- **Task carousel** — scale, opacity, blur, spacing.
- **Clear-all button** — placement and action row.

![](../pic/PEP/PixelLauncher/pic12.png)
</details>

<details>
<summary>🌀 Task cards carousel</summary>

Screen **Task carousel**.

- **Modify carousel — ON.**
- **Extra spacing −17 px, Min scale 0.93x, Min opacity 1.00.**
- **Card blur 12 px, Blur beyond bounds ON.**
- **Tint color #000000, strength 26%.**
- **Icon offset X 0 px, Y 0 px.**
- **Disable Live Tile ON** (static snapshots),
  Global scale OFF, Scale 100%.

![](../pic/PEP/PixelLauncher/pic13.png)
![](../pic/PEP/PixelLauncher/pic14.png)
![](../pic/PEP/PixelLauncher/pic15.png)
</details>

<details>
<summary>🧹 Clear-all button</summary>

- **Enable — ON.**
- **Hide Screenshot/Select row — OFF.**
- **Button mode — Bottom.**
- **Bottom margin — 3.00x.**

![](../pic/PEP/PixelLauncher/pic16.png)
</details>

<details>
<summary>🧷 Launcher tiles</summary>

Screen **Quick Settings tiles**.

- **Fixed tiles** — Double-tap sleep — **Not added**, **Bind tile**.
- **Configurable tiles** — Custom tile — **Bind tile**.

![](../pic/PEP/PixelLauncher/pic17.png)
</details>

<details>
<summary>🙈 Hidden apps</summary>

Screen **Hide apps from launcher**.

- **System apps — ON.**
- Search, **Applications** list with checkboxes (all unchecked in shot):
  4PDA, AdBlock, Authenticator, Barcode keyboard, BASIT, BCR, beeline, ByeByeDPI…
- Restart launcher to apply.

![](../pic/PEP/HideApp/pic1.png)
</details>

---

## Scroll effects

`Scroll Physics`

<details>
<summary>🌊 Main — profiles and spring</summary>

- **System Integration — Active — ON.**
- **Playground** — Example cards for testing.
- **Profiles** — Import / Export / Save / Online Configs.
- **Spring Physics** — Pull **1.51**, Stiffness **148.62**,
  Damping **1.00**, Fling **1.37**,
  Resistance **4.00**, Speed **168.52**.

![](../pic/PEP/Scroll/pic1.png)
![](../pic/PEP/Scroll/pic2.png)
![](../pic/PEP/Scroll/pic3.png)
![](../pic/PEP/Scroll/pic10.png)
</details>

<details>
<summary>📐 Deform groups (all Off in shots)</summary>

- **Vertical** — Off / Shrink / Grow.
  Intensity 0.31, Horizontal 0.38, Limit 0.10, Pivots 0.50.
- **Zoom (XY)** — Off. 0.20 / 0.20, Limit 0.10, Pivots 0.50.
- **Horizontal** — Off. 0.20 / 0.00, Limit 0.10, Pivots 0.50.
- Greyed out while Off.

![](../pic/PEP/Scroll/pic4.png)
![](../pic/PEP/Scroll/pic5.png)
![](../pic/PEP/Scroll/pic6.png)
</details>

<details>
<summary>🔧 Fine + per-app</summary>

- **System Parameters** — Input Smooth 0.50, Min Velocity 8.00,
  Min Value 0.60, PULL 0.40, FLING 0.70, Compose Divider 3.33, Smart Pivot.
- **Compose Delta Smoothing — ON.**
  Hybrid mode, Reference 10.00, Multiplier 0.00,
  Correction 0.33, Window 2.00, Ramp 1.00.
- **App Configuration — Add Application.**
  Shot: Pixel Launcher, Smoothing OFF, Disable ON, Multiplier 1.0.
- **Reset Settings** button.

![](../pic/PEP/Scroll/pic7.png)
![](../pic/PEP/Scroll/pic8.png)
![](../pic/PEP/Scroll/pic9.png)
</details>

---

## Heat — instant, no reboot

Profiles switch **in seconds on the running phone**.
Old screens may still offer a reboot — just press OK, it already works.

<details>
<summary>🌡 Global + per-app + queue</summary>

Screen **Thermals Manager**.

- **Global profile** — shot: **Battery +9c; Soc +90c — System —
  battery_medium_soc_off.json** (+ `+` button).
- **Tile profile queue — 0/5 — Add profile — Queue is empty.**
- **Show system apps — ON**, search, **Application profiles**.
- Row: 3 Button Navigation Bar — System — Global — same profile.
- Tap a row → profile picker: **Follow global** (selected in shot),
  **Stock — thermal_info_config.json**,
  **Battery +15c, +15c/+15c, +15c/+5c, +15c/+90c, +15c/+9c, +5c…**
- Global picker shows the same list with current check.

The phone watches the open app **every second** and swaps itself.

![](../pic/PEP/Thermal/pic1.png)
![](../pic/PEP/Thermal/pic2.png)
![](../pic/PEP/Thermal/pic3.png)
</details>

<details>
<summary>🧪 Config editor</summary>

Screen **Config editor**.

- **Source: Vendor original.**
- **Profile name — Custom thermal.**
- **File name (optional)** — empty, latin auto-convert.
- Tabs **SOC / Battery / All** (All in shot).
- **Save, Save and apply.**
- **Configurator — Showing 761 of 761 fields**, search,
  tree Root 761: battery, BIG, cam_therm, cellular-emergency, charge_therm…
- Expanded node shows rows like Coefficient, Combination,
  Formula MAXIMUM, HotHysteresis, HotThreshold, Multiplier 0.001,
  PassiveDelay 7000, PollingDelay 300000 — with **Known / Throttling** badges.

System configs are locked — clone before editing.

![](../pic/PEP/Thermal/pic4.png)
![](../pic/PEP/Thermal/pic5.png)
</details>

---

## Modules

<details>
<summary>🧩 Modules list (real shots)</summary>

Screen **LSPlant Addons — 0 installed — Active: 8 of 8**.

- **Import Addon — Select a .jar file.**
- **Active Apps — 5 apps with hooks** (expandable:
  Settings 2, System UI 2 — Ambient Extend + SystemUI Hooks,
  Camera 1, Pixel Launcher 1, 4PDA 1).
- **System modules**:
  - Icon Manager Settings UI v2.0.1
  - Settings Homepage Item v2.0.1
  - GCam Photo Torch v2.0.1
  - Launcher hooks (nexuslauncher) — Merged scope
  - Ambient Extend v2.0.1
  - SystemUI Hooks v2.2.22
  - IMS Carrier Config v2.0.1
  - Settings Icon Style Override v2.0.1
- Each: version, author, id, description, scope chip, on / off.
- Expanded card: **Module Settings + Import / Export / Check updates.**
- Tap scope → **Target Scope: Default / Custom / Merge**,
  Default Targets (e.g. com.android.settings), **Cancel / Save**.
- Custom targets → **Select apps** with Show system / Launchable only,
  search, checkboxes, **Cancel / Confirm**.

![](../pic/PEP/Addons/pic1.png)
![](../pic/PEP/Addons/pic2.png)
![](../pic/PEP/Addons/pic3.png)
![](../pic/PEP/Addons/pic4.png)
![](../pic/PEP/Addons/pic5.png)
![](../pic/PEP/Addons/pic6.png)
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
