# Final Acceptance Checklist — Level 2 Warden Pass

## Package and preservation

- [x] Existing uploaded project modified directly.
- [x] `project.godot` retained at project root.
- [x] Godot 4.7 and GL Compatibility settings preserved.
- [x] Prologue, Level 1, Level 3, Level 4, ending, menus, and results design preserved.
- [x] `.godot`, temporary files, logs, and build junk excluded from output.
- [x] Full-project and patch-only archives prepared with project-relative paths.

## Level 2 gameplay contract

- [x] Level begins FROZEN.
- [x] First Orb kick starts Kickoff.
- [x] Riddle is visible in the environment.
- [x] Objective does not reveal EAR → EYE → MOUTH.
- [x] Orb manual W/S and Up/Down aiming preserved.
- [x] EAR enables blind sound-memory charge.
- [x] Only Warden charge breaks the cracked wall.
- [x] EYE enables vision cone and projectile attack.
- [x] Projectile has hostile then reflectable presentation.
- [x] Only reflected projectile opens Echo Lock.
- [x] Gate opens temporarily and defers closing when occupied.
- [x] MOUTH enables scream shockwave.
- [x] Shockwave has one-hit protection.
- [x] Core opens for a limited window.
- [x] Direct kicks and closed-core contacts do not reduce core health.
- [x] Charged kick creates delayed Resonance Strike.
- [x] One exposure accepts one core hit.
- [x] Three hits defeat the Warden once.
- [x] Wrong rune resets sequence, damages once, resets Orb, and enrages Warden.
- [x] Orb has pedestal and out-of-bounds recovery.
- [x] Existing Niko transmission and ECHO Sigil/result flow preserved.

## Source validation

- [x] Static validator passes.
- [x] New and modified scripts pass gdlint.
- [x] New and modified scripts pass gdparse.
- [x] New scenes are included in smoke-test coverage.
- [x] New asset keys are included in manifest-test coverage.

## Requires Godot execution

- [ ] Godot headless import completed.
- [ ] In-engine Level 2 tests executed.
- [ ] Full interactive Level 2 playthrough completed.
- [ ] Every failure/retry path manually verified.
- [ ] Windows export generated and tested.
- [ ] Web export generated and tested.

Unchecked items require a Godot installation and matching export templates.
