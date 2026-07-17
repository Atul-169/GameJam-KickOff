# Test Report — Level 2: The Waking Warden

## Static validation — PASSED

Command:

```bash
python tools/static_validate.py
```

Validated areas include:

- all required existing and new resources;
- Godot 4.7 project metadata and fixed inputs;
- new Level 2 scenes and scripts;
- EAR → EYE → MOUTH strict sequence;
- objectives not revealing the sequence;
- environmental inscription;
- first-Orb-kick Kickoff;
- Warden hearing, vision, voice, and defeat stages;
- Warden-only cracked wall break;
- reflected-projectile-only Echo Lock;
- timed gate;
- shockwave one-hit behavior;
- delayed Resonance Strike and exposed-core guards;
- exactly three core segments;
- wrong-rune damage/reset/enrage;
- Orb pedestal and bounds recovery;
- existing single ECHO Sigil completion flow;
- existing Prologue and later-level regression safeguards;
- absence of `.godot`, cache, and temporary files.

Exact counts are written to `STATIC_VALIDATION_REPORT.txt`.

## GDScript source parser/linter — PASSED FOR CHANGED FILES

Commands:

```bash
gdlint <modified and added GDScript files>
gdparse <modified and added GDScript files>
```

All modified and added Level 2 scripts and tests passed the available `gdtoolkit 4.5.0` parser/linter.

A full-project linter run identifies pre-existing style-only issues in unrelated Prologue/Ancient Seal files. Those files were not changed because this pass was restricted to Level 2. The available parser did not report a parser failure in the changed files.

## Godot engine import — NOT EXECUTED

No Godot executable was installed or discoverable. The intended command remains:

```bash
godot --headless --editor --path <project_path> --quit
```

Godot engine parser error count is therefore not measured.

## Runtime smoke test — NOT EXECUTED

Runtime error count is not measured. The following require execution in Godot:

- platform and ricochet geometry tuning;
- Warden sound-charge readability;
- cracked-wall lure timing;
- projectile reflect window;
- four-second gate fairness;
- shockwave jump clearance;
- Resonance Strike/core overlap timing;
- full retry and completion playthrough;
- performance at target hardware.

## Godot tests included but not executed

- `tests/echo_sequence_test.gd`
- `tests/level2_echo_warden_test.gd`
- `tests/level2_orb_recovery_test.gd`
- updated `tests/project_smoke_test.gd`
- updated `tests/asset_manifest_test.gd`

These tests do not depend on final artwork or audio.

## Manual gameplay test — NOT EXECUTED

A complete interactive playthrough was not possible without Godot.

## Export tests — NOT EXECUTED

- Windows preset preserved: `build/windows/TheFirstKick.exe`
- Web preset preserved: `build/web/index.html`

No build output is included.
