# MAZ Coast Racing — native Godot edition (0.3.0)

First run `python scripts/fetch_game_assets.py` from the repository root to fetch
the checksum-pinned CC0 vehicle. Then open `project.godot` in Godot **4.7.2**, then run the main scene. This is the current
Android game. The parent repository retains the older web prototype for history.

- Native 3D scene and CharacterBody3D racing physics.
- Closed coastal circuit, five AI rivals, three laps and ordered checkpoints.
- Full-screen left/right touch and analog drag steering, independent of pedal fingers.
- Detailed CC0 Spectral GT RS, batched by material and moving assembly.
- Animated wheels, active wing, body roll, drift smoke, collision sparks and nitro flames.
- Steering, braking, handbrake drift, nitro, reset-to-track and three cameras (chase, hood, cockpit).
- Palm-lined circuit, pits, spectator stands, illuminated tunnel, sector gates and animated water.
- Automatic acceleration on by default; turn it off on the menu to use GAS.
- Synthesized engine audio and a locally saved personal best.

Keyboard: A/D or arrows steer; W/up gas; S/down brake; space drift; shift nitro;
R returns to the road; C switches camera; Escape pauses. Touch/drag the driving view to steer; pedal buttons keep their own fingers. Mouse
touch emulation also works in the editor.

The headless integration test injects real ScreenTouch events through the root
viewport (including two simultaneous fingers), verifies vehicle heading and nitro
consumption, releases, pause, AI movement, checkpoint validation and results.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/integration.gd --fixed-fps 60
```

The Android workflow installs official Godot templates and exports an ARM64 debug
APK, verified with Android apksigner. Package `com.mazvix.coastracing` is separate
from the previous web build so both can be installed. This is still an indie
prototype: visual/device performance, race balancing and production signing need
real-device testing before any store release. No AdMob plugin, ads, analytics,
network permission or model API calls are enabled in this native edition.

Original game code: Apache-2.0 (parent LICENSE). Spectral GT RS by
JaronKBragg7337: CC0-1.0, with pinned source and license in `assets/spectral/`. Godot is MIT-licensed; engine
copyright and third-party notices: https://godotengine.org/license/ . No commercial
car brands, third-party music or paid assets are used.

## Test build upgrades

Version 0.2 used a disposable CI debug certificate. Uninstall 0.2 before installing
0.3 if Android reports a signature conflict (uninstalling clears local records).
Starting with 0.3 the workflow caches a debug-only keystore for subsequent testing
builds. This is not a production signing key; use your own private release key
for store distribution.
