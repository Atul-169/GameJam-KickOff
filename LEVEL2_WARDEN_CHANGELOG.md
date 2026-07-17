# Level 2 Warden Redesign Changelog

## Scope

Only Level 2 and its directly required reusable Orb/Rune support, tests, asset manifest entries, validator rules, and documentation were changed. No gameplay redesign was applied to the Prologue, Level 1, Level 3, Level 4, ending, menus, or results flow.

## Implemented

- Renamed Level 2 to **Archive of Echoes — The Waking Warden**.
- Replaced SUN/EAR/ECHO with strict **EAR/EYE/MOUTH** progression.
- Added the full in-world archive inscription without exposing the answer in objectives.
- Expanded the arena to 6500 pixels with lower and upper platform routes.
- Preserved W/S and arrow-key Orb angle selection.
- Added stable per-stage Orb pedestals and bounds recovery.
- Added a dedicated dormant Echo Warden scene and state machine.
- EAR enables blind sound-memory charges.
- Added a Warden-only cracked wall break and stun response.
- EYE enables vision cone, pursuit, and reflectable echo projectiles.
- Added reflected-projectile-only Echo Lock.
- Added a safe four-second gate with closing deferral when the doorway is occupied.
- MOUTH enables a one-hit-per-wave scream shockwave.
- Added level-specific charged Resonance Strike.
- Added a real Core Area hitbox; direct body kicks cannot reduce core health.
- Added three-segment core health and one-hit-per-exposure protection.
- Added wrong-rune damage, visual reset, Orb reset, and temporary Warden enrage.
- Preserved Niko transmission, ECHO Sigil, result screen, and Level 3 continuation.
- Added safe temporary projectile/shockwave/strike cleanup.
- Added procedural fallback keys for Warden, wall, lock, and timed gate.

## Tests added or updated

- Updated `tests/echo_sequence_test.gd` for EAR/EYE/MOUTH.
- Added `tests/level2_echo_warden_test.gd`.
- Added `tests/level2_orb_recovery_test.gd`.
- Expanded `tests/project_smoke_test.gd` with all new Level 2 scenes.
- Expanded `tests/asset_manifest_test.gd` with the new asset keys.
- Expanded `tools/static_validate.py` with Level 2 progression, safety, reward, and resource checks.

## Runtime status

Static validation and source parsing were performed. No Godot executable was available, so engine import, runtime smoke testing, interactive balancing, and exports were not executed.
