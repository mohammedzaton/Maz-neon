# MAZ Coast Racing — native Godot edition (0.2.0)

Open `project.godot` in Godot **4.7.2**, then run the main scene. This is the current
Android game. The parent repository retains the older web prototype for history.

- Native 3D scene and CharacterBody3D racing physics.
- Closed coastal circuit, five AI rivals, three laps and ordered checkpoints.
- Native TouchScreenButton controls supporting simultaneous fingers.
- Steering, braking, handbrake drift, nitro, reset-to-track and two cameras.
- Procedural car bodies, asphalt, curbs, barriers, city and sunset environment.
- Automatic acceleration on by default; turn it off on the menu to use GAS.
- Synthesized engine audio and a locally saved personal best.

Keyboard: A/D or arrows steer; W/up gas; S/down brake; space drift; shift nitro;
R returns to the road; C switches camera; Escape pauses. Touch buttons are always
visible, so they can also be tested using mouse touch emulation in the editor.

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

Original code/assets: Apache-2.0 (parent LICENSE). Godot is MIT-licensed; engine
copyright and third-party notices: https://godotengine.org/license/ . No commercial
car brands, third-party music or paid assets are used.
