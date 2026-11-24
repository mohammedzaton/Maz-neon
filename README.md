# MAZ Coast Racing 0.3 — Spectral Edition

Current Android build: [`godot/`](godot/README.md). Version 0.3 introduces
full-screen touch/drag steering, a checksum-pinned CC0 Spectral GT RS vehicle,
animated wheels and active wing, drift smoke, collision sparks, nitro flames and
speed effects. The circuit adds palm-lined sections, pits, stands, an illuminated
tunnel, sector gates and animated water.

Run `python scripts/fetch_game_assets.py` before opening the native project.
The native Android workflow builds **MAZ-Coast-Racing-0.3-APK**. No ads, analytics,
network access or model API calls are enabled in the game. This remains an indie
testing build and needs real-device handling and performance feedback.

---

## Archived web prototype documentation

# MAZ Neon Rush

An original offline arcade highway racer for Android and the web. Drive a fictional
neon sports car through midnight traffic, charge nitro with near misses and unlock
three rides using coins earned by racing.

**Version 0.1.0 is a playable testing build, not a store-ready release.**

## Three open-source projects integrated

| Project | Actual integration | License |
| --- | --- | --- |
| [Three.js](https://github.com/mrdoob/three.js) | 3D road, cars, city, camera and lighting | MIT |
| [cannon-es](https://github.com/pmndrs/cannon-es) | Dynamic player, kinematic traffic, collision events | MIT |
| [nipplejs](https://github.com/yoannmoinet/nipplejs) | Analog touch steering | MIT |

These projects are dependencies; this repository does not claim authorship of them.
Capacitor packages the local web build as an Android app. The optional community
AdMob bridge is included, disabled by default. Original game logic, vehicle shapes,
scene layout, interface, audio synthesis and software-rendering fallback are here.
Full upstream notices: `public/THIRD_PARTY_LICENSES.txt`.

## Features

- 3 km sprint and endless highway modes.
- Touch joystick, brake and hold-to-boost nitro; keyboard controls on desktop.
- Physics-based traffic collisions, health, near misses, race results and coins.
- Three fictional unlockable cars, local save recovery and a personal distance record.
- Pause/resume, Android background handling, landscape immersive mode.
- Synthesized engine audio; no music or external paid assets.
- WebGL 2 rendering with a Canvas perspective fallback when WebGL is unavailable.
- All play assets bundled locally. No model API, account or network needed to race.

## Run

Requires Node.js 22+; development tested with Node 24.

```sh
npm ci
npm test
npm run dev
```

Desktop: A/D or left/right to steer, S/down to brake, space/shift for nitro,
Escape to pause. The car accelerates automatically. Android uses touch controls.

## Legacy web APK

The former `Android APK` GitHub Actions workflow built an installable debug APK on pushes
to `main`, or manually via Actions. Download artifact **MAZ-Neon-Rush-APK**, unzip,
then install `MAZ-Neon-Rush-debug.apk`. This is signed with the runner's debug key,
not a production signing key. Future debug builds may require uninstalling the old
one if the key changes; uninstalling removes local progress.

To build locally, install Android Studio/SDK 36 and Java 21:

```sh
npm run android:prepare
cd android
# Windows: gradlew.bat assembleDebug
./gradlew assembleDebug
```

`android/app/build/outputs/apk/debug/app-debug.apk` is the result.
For Play Store distribution, create and securely retain your own signing key and
build a signed release AAB. Do not publish debug builds to the store.

## Ads and release preparation

No ads are enabled in the default APK. The integration supports optional rewarded
ads on the results screen; rewards are granted only from the SDK reward event.
There are no interstitials during races and no fake ad rewards on web.
See [Android release guide](docs/ANDROID_RELEASE_AR.md) before enabling ads.

## Validation limits

Automated tests cover economy, corrupted saves, purchase restrictions, collision
callbacks and road boundaries. The web build is compiled. Browser QA in the build
environment uses the Canvas fallback because its browser has WebGL disabled. The
Three.js path still requires physical Android device testing, alongside touch,
WebView performance, resume behavior and the optional native advertising flow.
This game is an initial prototype, not a finished commercial title.

## Maintainer & license

Mohammed Zaton — mohammed.zaton2@gmail.com.
Original code: Apache-2.0, preserving the license selected for this repository.
Third-party dependencies retain their own licenses and copyright notices.
