# Spectral GT RS

Upstream: https://github.com/JaronKBragg7337/spectral-gt-rs
Author: JaronKBragg7337. Public-domain dedication: CC0-1.0; see LICENSE.txt.
Pinned revision: `34499c501908818a2b08e589a7aecf963343cee7`.
File: `spectral_gt_rs_game_ready.glb` (4,688,844 bytes).
SHA-256: `e7b7f0d9de0c3bc3897c8134b1ceae5631b1da2690d336df18c3ea82e7238c73`.

Run `python scripts/fetch_game_assets.py` from the repository root before opening
Godot. CI downloads this exact version, checks the hash, and bundles it inside
the APK. No downloads or model API calls occur during gameplay.

Adaptation: geometry is batched by material and moving assembly; paint finishes
are recolored per rival. Wheel, suspension roll and active-wing movement are
implemented by the game. The original animations remain in the source GLB.
The upstream project and car model are not claimed as original MAZ authorship.
