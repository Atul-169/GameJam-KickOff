# Asset Replacement Guide

The project uses:

- `res://resources/asset_manifest.json` for stable asset keys and fixed files.
- `res://resources/animation_manifest.json` for horizontal sprite-strip slicing.

Normal asset replacement does not require gameplay-code changes.

## Sprite strips

- Orientation: horizontal, left to right.
- Frames must have equal width and height.
- Use transparent PNG files.
- Keep character feet on a consistent baseline across animations.
- Leave transparent padding so limbs and effects are not clipped.
- Set `frames`, `fps`, and `loop` in `animation_manifest.json`.
- Invalid or missing strips fall back to visible procedural animations.

Required Arin animations:

`idle`, `run`, `jump`, `fall`, `kick`, `charged_kick`, `push_fail`, `hurt`, `knockout`, `victory`.

Required Niko animations:

`idle`, `run`, `fall`, `trapped`, `rescue`.

## Fixed character paths

- Arin: `res://assets/characters/arin/arin_<animation>.png`
- Niko: `res://assets/characters/niko/niko_<animation>.png`
- Astra: `res://assets/characters/astra/astra.png`
- Enemies: fixed paths under `res://assets/enemies/`

## Fixed environment and gameplay paths

The following semantic keys must remain separate:

- Rotating gear: `res://assets/environment/rotating_gear.png`
- Falling rock: `res://assets/environment/falling_rock.png`
- Weak platform: `res://assets/environment/weak_platform.png`
- Shortcut lift: `res://assets/environment/shortcut_lift.png`
- Breakable pillar: `res://assets/environment/breakable_pillar.png`
- Exit gate: `res://assets/interactables/exit_gate.png`
- Rune jar: `res://assets/interactables/rune_jar.png`

Do not place rotating-gear art at the falling-rock path. Missing falling-rock art displays a readable grey/brown procedural rock labelled `ROCK`.

## Recommended texture limits

- Character strips: up to 4096×1024 when practical
- Individual enemies/interactables: up to 1024×1024
- UI panels/backgrounds: up to 2048×2048
- Icons and VFX: generally 256–1024 pixels per dimension

Power-of-two sizes are optional in Godot 4. Avoid excessive transparent margins.

## UI replacement

Place UI PNGs at their fixed manifest paths. Available textures are applied through texture-backed controls/styles; missing textures use readable `StyleBoxFlat` and procedural fallbacks.

## Audio replacement

- Music: OGG recommended.
- Short SFX: WAV or OGG.
- Keep fixed filenames and extensions unless intentionally updating the manifest.
- Missing audio is ignored safely.
- Music and SFX volumes are independent and saved to `user://settings.cfg`.

## Font replacement

Place the font at `res://assets/fonts/main_font.ttf`. Godot's default font is used when it is absent.

## Reimport steps

1. Replace the file at the exact fixed path.
2. Update only `frames`, `fps`, or `loop` in `animation_manifest.json` when required.
3. Return to Godot and allow automatic reimport, or select the file and press **Reimport**.
4. Run the relevant scene.
5. Verify visual scale, baseline, collision alignment, animation timing, and semantic correctness.

No normal character, enemy, environment, interactable, UI, VFX, audio, or font replacement requires gameplay-script edits.

## Level 2 — The Waking Warden assets

The redesigned archive adds these optional fixed paths:

| Key | Path | Suggested use |
|---|---|---|
| `echo_warden` | `res://assets/enemies/echo_warden/echo_warden.png` | Dormant and awakened Warden body |
| `echo_cracked_wall` | `res://assets/environment/echo_cracked_wall.png` | Warden-charge breakable wall |
| `echo_timed_gate` | `res://assets/interactables/echo_timed_gate.png` | Temporary MOUTH chamber gate |
| `echo_seal_lock` | `res://assets/interactables/echo_seal_lock.png` | Reflected-projectile lock |

The Echo Core continues using `assets/vfx/boss_core.png`. Projectiles use the existing projectile trail key, and runes use existing procedural/rune activation support.

Place replacement PNGs at the exact paths and reimport in Godot. Normal replacement requires no code changes. Keep transparent margins modest so collision/readability alignment remains predictable.
