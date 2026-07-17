# The First Kick: Echoes Beneath

A Godot **4.7** 2D side-scrolling mystery, platforming, puzzle, and action game targeting Windows and Web with the GL Compatibility renderer.

This archive continues directly from the uploaded cinematic-intro project. The Prologue cinematic, Level 1, Level 3, Level 4, ending, menus, inputs, autoloads, dialogue queue, reset protection, fixed asset paths, and procedural fallbacks are preserved. Only Level 2 has been redesigned.

## Opening cinematic

The opening remains an automatic in-engine cinematic. Arin kicks the football through scripted motion, Niko runs after it and falls through the Ancient Seal, Arin fails to open the seal by hand, and Astra appears. Player control begins after Astra's introduction, with **Kick the Ancient Seal** as the first gameplay objective.

## Redesigned Level 2

Level 2 is now titled **Archive of Echoes — The Waking Warden**.

It combines:

- an environmental riddle;
- manual Echo Orb aiming;
- multi-layer platforming;
- a progressive Warden encounter;
- projectile reflection;
- a timed gate challenge;
- a three-hit exposed-core mini-boss loop.

### Riddle

The archive inscription reads:

> First, the silent hall must hear.  
> Then, the watcher learns to see.  
> Only after sight returns may the sealed tongue speak.  
> When all three awaken, silence the heart that echoes.

The required rune order is **EAR → EYE → MOUTH**, but the HUD never displays the full solution or explicitly names the next rune.

### Level flow

1. The room begins **FROZEN** with the dormant Echo Warden visible.
2. The first kick of the Echo Orb starts **KICKOFF** and activates the room.
3. EAR requires an aimed ricochet and awakens the blind Warden's hearing.
4. The Warden charges toward remembered sound positions; lure it into the cracked wall to open the upper route.
5. EYE requires a new elevated Orb shot. It gives the Warden vision and a telegraphed reflectable projectile.
6. A reflected Warden projectile is the only attack that opens the Echo Lock and its four-second gate.
7. Kick the Orb through the temporary opening to activate MOUTH.
8. MOUTH adds a jumpable scream shockwave and briefly exposes the Echo Core.
9. A charged kick creates a delayed cyan **Resonance Strike**. Only that delayed strike can damage the exposed core.
10. Three valid core hits silence the Warden, open the archive exit, play the existing Niko transmission, and preserve the normal ECHO Sigil/results flow.

### Wrong-rune consequence

A wrong rune contact:

- counts one mistake;
- clears visible rune progress;
- returns the Orb to the initial pedestal with zero velocity;
- damages Arin by exactly one health;
- enrages the Warden temporarily;
- keeps already-awakened Warden abilities;
- does not restart the entire level.

## Level 2 controls

| Action | Input |
|---|---|
| Move | A / D or Left / Right |
| Jump | Space |
| Aim Orb upward | W or Up Arrow |
| Aim Orb downward | S or Down Arrow |
| Normal Kick | J or Left Mouse |
| Charged Kick / Resonance Kick | Hold and release K or Right Mouse |
| Restart challenge | R |
| Pause | Escape |

The existing manual Orb aiming arrow and angle label remain active while Arin is near a stationary Orb.

## Asset replacement

The project still runs without final artwork. Newly supported fixed paths are:

- `res://assets/enemies/echo_warden/echo_warden.png`
- `res://assets/environment/echo_cracked_wall.png`
- `res://assets/interactables/echo_timed_gate.png`
- `res://assets/interactables/echo_seal_lock.png`

Missing files use readable procedural visuals through `AssetRegistry`. Normal asset replacement requires no gameplay-script changes.

## Open in Godot

1. Install Godot 4.7 or a compatible Godot 4.x release.
2. Extract the archive.
3. Import the root-level `project.godot`.
4. Allow resource import to finish.
5. Run the project with F6/F5.

The project uses a 1920×1080 base viewport and GL Compatibility rendering.

## Important Level 2 files

- `scripts/levels/level_02_echo_archive.gd`
- `scripts/enemies/echo_warden.gd`
- `scripts/enemies/warden_echo_projectile.gd`
- `scripts/enemies/echo_core_hitbox.gd`
- `scripts/environment/echo_breakable_wall.gd`
- `scripts/interactables/echo_timed_gate.gd`
- `scripts/interactables/echo_seal_lock.gd`
- `scripts/interactables/resonance_strike.gd`
- `scripts/hazards/echo_shockwave.gd`
- `scripts/interactables/echo_orb.gd`
- `scripts/interactables/puzzle_rune.gd`
- `tests/level2_echo_warden_test.gd`
- `tests/level2_orb_recovery_test.gd`

## Validation performed

```bash
python tools/static_validate.py
gdlint <all modified and added GDScript files>
gdparse <all modified and added GDScript files>
unzip -t <final archive>
```

Source validation results are recorded in `STATIC_VALIDATION_REPORT.txt`, `TEST_REPORT.md`, and `LEVEL2_WARDEN_CHANGELOG.md`.

No Godot executable was available in the environment. Godot engine import, runtime playthrough, in-engine test execution, manual gameplay balancing, and Windows/Web exports therefore remain unverified.

## Export presets

- Windows Desktop: `build/windows/TheFirstKick.exe`
- Web: `build/web/index.html`

No exported builds are included because Godot and export templates were unavailable.
