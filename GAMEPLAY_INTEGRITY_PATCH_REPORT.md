# Gameplay Integrity Patch Report

## Scope

This pass modified the uploaded runtime-fixed project directly. It did not create a new project or add levels, bosses, enemies, abilities, or story branches.

## 1. Prologue bypass correction

`prologue_forest.gd` now owns an explicit sequence state. Every target and story callback checks that state before progressing.

`AncientSeal` now contains two distinct collision roles:

- The root Area2D is the hand-interaction target.
- `SealKickReceiver` is the kick target.

At initial load both are disabled. After Niko finishes falling, only the hand-interaction target is enabled. After the failed hand attempt and the full Astra clue, the kick receiver is enabled. Opening and transition callbacks are one-shot guarded.

## 2. Frozen Court correction

`EnemyBase` rejects all combat mutation when `world_active` is false. This includes health damage, knockback, hit feedback, stun, death, and heavy-collision effects.

Rune Jars, breakable pillars, and suspended projectiles implement their own frozen-state collision and behavior guards. The Level 3 controller activates them only after the Bell Kickoff and rejects wave/boss callbacks outside ACTIVE state.

## 3. Dialogue queue

`GameHUD` now owns the single dialogue queue used by EventBus dialogue requests.

The queue provides:

- FIFO order for equal-priority story lines
- Priority protection against low-priority system messages
- One processor and one current line
- Automatic duration advance
- Space/E/Enter/Left-Mouse manual advance
- Input consumption before Arin gameplay input
- Optional player-lock sequences
- Completion/cancellation signals
- Generation-token invalidation on clear, restart, or scene exit

Required multi-line story sequences were updated to await the queue before continuing or opening results.

## 4. Tests added

- `res://tests/prologue_sequence_guard_test.gd`
- `res://tests/frozen_combat_test.gd`
- `res://tests/dialogue_queue_test.gd`

The tests do not depend on final artwork or audio.

## 5. Validation status

### Static/source validation

- Scripts: 71
- Scenes: 36
- Manifest entries: 83
- Static checks: 154
- Static errors: 0
- Static warnings: 0
- gdlint problems: 0
- Targeted gdparse failures: 0

### Godot parser/import

Not executed. No Godot executable was available.

### Runtime smoke test

Not executed. Runtime error count is not measured.

### Manual gameplay

Not executed.

### Export

Windows and Web presets remain present, but builds were not generated because Godot and export templates were unavailable.

## 6. Remaining work on a Godot-equipped machine

Run headless import, all test scripts, a full gameplay regression, and Windows/Web exports. Verify collision timing and dialogue pacing interactively before final asset integration.
