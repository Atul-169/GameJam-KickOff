from __future__ import annotations

from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
warnings: list[str] = []
checks: list[tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str = "") -> None:
    checks.append((name, bool(condition), detail))
    if not condition:
        errors.append(f"{name}: {detail}")


for rel in [
    "project.godot",
    "export_presets.cfg",
    "resources/asset_manifest.json",
    "resources/animation_manifest.json",
]:
    check(f"core file {rel}", (ROOT / rel).is_file(), "missing")

asset = json.loads((ROOT / "resources/asset_manifest.json").read_text())
animation = json.loads((ROOT / "resources/animation_manifest.json").read_text())
check("asset manifest is dictionary", isinstance(asset, dict), type(asset).__name__)
check(
    "asset manifest astra key",
    asset.get("astra") == "res://assets/characters/astra/astra.png",
    repr(asset.get("astra")),
)
check(
    "asset manifest falling rock key",
    asset.get("falling_rock")
    == "res://assets/environment/falling_rock.png",
    repr(asset.get("falling_rock")),
)
check(
    "falling rock asset is separate from rotating gear",
    asset.get("falling_rock") != asset.get("rotating_gear"),
    repr(asset.get("falling_rock")),
)
check(
    "Echo Warden asset key",
    asset.get("echo_warden")
    == "res://assets/enemies/echo_warden/echo_warden.png",
    repr(asset.get("echo_warden")),
)
check(
    "Echo cracked wall asset key",
    asset.get("echo_cracked_wall")
    == "res://assets/environment/echo_cracked_wall.png",
    repr(asset.get("echo_cracked_wall")),
)
check(
    "Echo timed gate asset key",
    asset.get("echo_timed_gate")
    == "res://assets/interactables/echo_timed_gate.png",
    repr(asset.get("echo_timed_gate")),
)
check(
    "Echo seal lock asset key",
    asset.get("echo_seal_lock")
    == "res://assets/interactables/echo_seal_lock.png",
    repr(asset.get("echo_seal_lock")),
)
check(
    "all manifest values are strings",
    all(isinstance(value, str) for value in asset.values()),
)
image_extensions = {".png", ".jpg", ".jpeg", ".webp", ".svg"}
audio_extensions = {".wav", ".ogg", ".mp3"}
font_extensions = {".ttf", ".otf", ".woff", ".woff2"}
for key, value in asset.items():
    extension = Path(value).suffix.lower()
    if key.endswith("_sfx") or key.endswith("_music"):
        if extension not in audio_extensions:
            errors.append(f"audio key {key} has invalid extension {extension}")
    elif key == "main_font":
        if extension not in font_extensions:
            errors.append(f"font key {key} has invalid extension {extension}")
    elif extension not in image_extensions:
        errors.append(f"visual key {key} has invalid extension {extension}")

required_animations = {
    "arin": [
        "idle",
        "run",
        "jump",
        "fall",
        "kick",
        "charged_kick",
        "push_fail",
        "hurt",
        "knockout",
        "victory",
    ],
    "niko": ["idle", "run", "fall", "trapped", "rescue"],
}
for actor, names in required_animations.items():
    actor_data = animation.get(actor, {})
    check(f"animation actor {actor}", isinstance(actor_data, dict))
    for name in names:
        entry = actor_data.get(name)
        check(f"animation {actor}.{name}", isinstance(entry, dict), "missing")
        if isinstance(entry, dict):
            check(
                f"animation frames {actor}.{name}",
                isinstance(entry.get("frames"), int) and entry["frames"] > 0,
                repr(entry.get("frames")),
            )
            check(
                f"animation fps {actor}.{name}",
                isinstance(entry.get("fps"), (int, float)) and entry["fps"] > 0,
                repr(entry.get("fps")),
            )
            check(
                f"animation key {actor}.{name}",
                entry.get("asset_key") in asset,
                repr(entry.get("asset_key")),
            )

project_text = (ROOT / "project.godot").read_text()
compact_project = project_text.replace(" ", "")
for action in [
    "move_left",
    "move_right",
    "jump",
    "kick",
    "charged_kick",
    "interact",
    "restart",
    "pause",
]:
    check(f"input action {action}", f"{action}={{" in compact_project, "not serialized")
check(
    "Godot 4.7 project feature",
    'config/features=PackedStringArray("4.7", "GL Compatibility")' in project_text,
    "project.godot is not targeted to Godot 4.7",
)
for name, path in {
    "EventBus": "res://autoload/event_bus.gd",
    "GameState": "res://autoload/game_state.gd",
    "SceneManager": "res://autoload/scene_manager.gd",
    "AudioManager": "res://autoload/audio_manager.gd",
    "AssetRegistry": "res://autoload/asset_registry.gd",
}.items():
    check(
        f"autoload {name}",
        f"{name}=" in project_text and path in project_text,
        "missing or wrong path",
    )

required_paths = [
    "scenes/core/main.tscn",
    "scenes/characters/arin.tscn",
    "scenes/characters/niko.tscn",
    "scenes/levels/prologue_forest.tscn",
    "scenes/levels/level_01_gear_hall.tscn",
    "scenes/levels/level_02_echo_archive.tscn",
    "scenes/levels/level_03_guardian_court.tscn",
    "scenes/levels/level_04_sealed_heart.tscn",
    "scenes/enemies/stone_guardian.tscn",
    "scenes/enemies/arc_guardian.tscn",
    "scenes/enemies/echo_shade.tscn",
    "scenes/enemies/echo_warden.tscn",
    "scenes/enemies/warden_echo_projectile.tscn",
    "scenes/environment/echo_breakable_wall.tscn",
    "scenes/interactables/echo_timed_gate.tscn",
    "scenes/interactables/echo_seal_lock.tscn",
    "scenes/interactables/resonance_strike.tscn",
    "scenes/hazards/echo_shockwave.tscn",
    "scenes/enemies/shadow_hunter.tscn",
    "scenes/enemies/gatekeeper.tscn",
    "scenes/enemies/keeper.tscn",
    "scenes/ui/game_hud.tscn",
    "scenes/ui/main_menu.tscn",
    "scenes/ui/pause_menu.tscn",
    "scenes/ui/settings_menu.tscn",
    "scenes/ui/results_screen.tscn",
    "scenes/ui/fail_screen.tscn",
    "scenes/ui/ending_screen.tscn",
    "tests/project_smoke_test.gd",
    "tests/scene_validation_test.gd",
    "tests/asset_manifest_test.gd",
    "tests/sigil_grant_test.gd",
    "tests/input_map_test.gd",
    "tests/animation_manifest_test.gd",
    "tests/reset_state_test.gd",
    "tests/boss_phase_test.gd",
    "tests/spawn_position_test.gd",
    "tests/echo_sequence_test.gd",
    "tests/level2_echo_warden_test.gd",
    "tests/level2_orb_recovery_test.gd",
    "tests/restart_guard_test.gd",
    "tests/final_niko_randomization_test.gd",
    "tests/prologue_sequence_guard_test.gd",
    "tests/frozen_combat_test.gd",
    "tests/dialogue_queue_test.gd",
    "tests/dialogue_input_safety_test.gd",
    "tests/prologue_cinematic_test.gd",
    "tests/automatic_dialogue_test.gd",
    "scripts/cutscenes/prologue_cinematic.gd",
    "scripts/interactables/seal_kick_receiver.gd",
]
for rel in required_paths:
    check(f"required path {rel}", (ROOT / rel).is_file(), "missing")

resource_pattern = re.compile(r'"(res://[^"\n]+)"')
for path in [*ROOT.rglob("*.tscn"), ROOT / "project.godot"]:
    text = path.read_text(errors="replace")
    for reference in resource_pattern.findall(text):
        local_path = ROOT / reference[6:]
        if not local_path.exists() and reference not in asset.values():
            errors.append(f"missing resource reference {path.relative_to(ROOT)}: {reference}")

load_pattern = re.compile(r'(?:preload|load)\(\s*["\'](res://[^"\']+)["\']\s*\)')
for path in ROOT.rglob("*.gd"):
    text = path.read_text(errors="replace")
    for reference in load_pattern.findall(text):
        local_path = ROOT / reference[6:]
        if not local_path.exists() and reference not in asset.values():
            errors.append(f"missing script load {path.relative_to(ROOT)}: {reference}")

classes: dict[str, list[str]] = {}
for path in ROOT.rglob("*.gd"):
    match = re.search(r"^class_name\s+(\w+)", path.read_text(errors="replace"), re.MULTILINE)
    if match:
        classes.setdefault(match.group(1), []).append(str(path.relative_to(ROOT)))
for class_name, locations in classes.items():
    if len(locations) > 1:
        errors.append(f"duplicate class_name {class_name}: {locations}")

for path in [*ROOT.rglob("*.gd"), *ROOT.rglob("*.tscn")]:
    text = path.read_text(errors="replace").lower()
    for marker in ["todo", "fixme", "pseudocode"]:
        if marker in text:
            errors.append(f"unfinished marker {marker.upper()} in {path.relative_to(ROOT)}")

state_text = (ROOT / "autoload/game_state.gd").read_text()
check(
    "duplicate sigil guard",
    "if not sigils.has(id) or bool(sigils[id]):" in state_text and "return false" in state_text,
)
for rel in [
    "scripts/levels/level_01_gear_hall.gd",
    "scripts/levels/level_02_echo_archive.gd",
    "scripts/levels/level_03_guardian_court.gd",
]:
    text = (ROOT / rel).read_text()
    check(f"no direct reward grant in {rel}", "grant_sigil(" not in text, "direct grant remains")

final_text = (ROOT / "scripts/levels/level_04_sealed_heart.gd").read_text()
check(
    "memory objective hides answer",
    "Remember the path revealed before the Kickoff." in final_text,
)
check(
    "memory layout has multiple safe arrangements",
    "MEMORY_LAYOUTS" in final_text and final_text.count("Vector2(") >= 18,
)
check(
    "phase 3 exposed window exists",
    "begin_final_exposure" in final_text and "_keeper_defeated_sequence" in final_text,
)
keeper_text = (ROOT / "scripts/enemies/keeper.gd").read_text()
check(
    "phase 2 uses positional trap validation",
    "trap.can_break(" in keeper_text and "trap.try_break(" in keeper_text,
)
check(
    "final charged finish required",
    "if not charged:" in keeper_text and "final_exposed" in keeper_text,
)

level_manager_text = (ROOT / "scripts/levels/level_manager.gd").read_text()
spawn_function = level_manager_text.split("func spawn_scene", 1)[1].split(
    "func _create_background", 1
)[0]
position_index = spawn_function.find(".position = position_value")
add_child_index = spawn_function.find("add_child(node)")
check(
    "spawn position assigned before add_child",
    position_index >= 0
    and add_child_index >= 0
    and position_index < add_child_index,
)

level_two_text = (ROOT / "scripts/levels/level_02_echo_archive.gd").read_text()
tracker_text = (ROOT / "scripts/components/echo_sequence_tracker.gd").read_text()
warden_text = (ROOT / "scripts/enemies/echo_warden.gd").read_text()
orb_text = (ROOT / "scripts/interactables/echo_orb.gd").read_text()
wall_text = (ROOT / "scripts/environment/echo_breakable_wall.gd").read_text()
lock_text = (ROOT / "scripts/interactables/echo_seal_lock.gd").read_text()
gate_text = (ROOT / "scripts/interactables/echo_timed_gate.gd").read_text()
shockwave_text = (ROOT / "scripts/hazards/echo_shockwave.gd").read_text()
strike_text = (ROOT / "scripts/interactables/resonance_strike.gd").read_text()
check(
    "Level 2 title updated",
    'level_title = "Archive of Echoes — The Waking Warden"' in level_two_text,
)
check(
    "Level 2 strict EAR EYE MOUTH order",
    'const ORDER: Array[String] = ["EAR", "EYE", "MOUTH"]'
    in level_two_text
    and '["EAR", "EYE", "MOUTH"]' in tracker_text
    and "sequence.register(id)" in level_two_text
    and "return Result.WRONG" in tracker_text,
)
check(
    "Level 2 objective does not reveal sequence",
    "Next rune:" not in level_two_text
    and "Activate EAR" not in level_two_text
    and "EAR → EYE → MOUTH" not in level_two_text,
)
check(
    "Level 2 environmental riddle present",
    "THE SILENT HALL MUST HEAR" in level_two_text
    and "THE WATCHER LEARNS TO SEE" in level_two_text
    and "MAY THE SEALED TONGUE SPEAK" in level_two_text,
)
check(
    "Level 2 starts on first Orb Kickoff",
    "orb.kicked_off.connect(_orb_started)" in level_two_text
    and "start_kickoff()" in level_two_text
    and "warden.set_world_active(true)" in level_two_text,
)
check(
    "Warden progressive awakenings",
    all(token in warden_text for token in [
        "func awaken_hearing",
        "func awaken_vision",
        "func awaken_voice",
        "Awakening.DORMANT",
        "projectile_requested.emit",
        "shockwave_requested.emit",
    ]),
)
check(
    "Warden hearing charge breaks only dedicated wall",
    "notify_sound" in warden_text
    and "receive_warden_charge" in warden_text
    and "func receive_warden_charge" in wall_text
    and "if not world_active or broken_once" in wall_text,
)
check(
    "Reflected projectile opens timed gate",
    "echo_lock.unlocked.connect(_echo_lock_unlocked)" in level_two_text
    and "open_temporarily(4.2)" in level_two_text
    and "not reflected" in lock_text
    and "func open_temporarily" in gate_text,
)
check(
    "Mouth enables shockwave and core loop",
    "warden.awaken_voice()" in level_two_text
    and "shockwave_requested" in warden_text
    and "body.take_damage(1" in shockwave_text
    and "CORE_MAX_HEALTH := 3" in warden_text,
)
check(
    "Core accepts only delayed Resonance Strike",
    "func receive_core_strike" in warden_text
    and "action != Action.CORE_EXPOSED" in warden_text
    and "core_hit_this_window" in warden_text
    and "is_resonance_strike" in strike_text
    and "create_timer(0.35)" in level_two_text,
)
check(
    "Wrong rune penalty is complete and one-shot guarded",
    "sequence.reset()" in level_two_text
    and "_clear_rune_visuals()" in level_two_text
    and "player.take_damage(1" in level_two_text
    and "warden.enrage(4.5)" in level_two_text
    and "active_contacts"
    in (ROOT / "scripts/interactables/puzzle_rune.gd").read_text(),
)
check(
    "Orb pedestal recovery support",
    "func set_pedestal" in orb_text
    and "func set_reset_bounds" in orb_text
    and "not reset_bounds.has_point(global_position)" in orb_text,
)
check(
    "Level 2 completion remains single Sigil flow",
    'complete_level("echo")' in level_two_text
    and "grant_sigil(" not in level_two_text
    and "if warden_defeated:" in level_two_text,
)

main_text = (ROOT / "scripts/core/main.gd").read_text()
check(
    "restart completion/results/transition guard",
    "func can_restart_current_level()" in main_text
    and "not results_open" in main_text
    and "not transition_in_progress" in main_text
    and "current_level.can_restart()" in main_text,
)
check(
    "restart input is consumed",
    "set_input_as_handled()"
    in (ROOT / "scripts/characters/arin.gd").read_text(),
)
check(
    "real Niko selection is randomized once per phase",
    "real_niko_index = select_real_niko_index" in final_text
    and "illusion.is_real = i == real_niko_index" in final_text
    and "rng.randi_range" in final_text,
)
check(
    "falling rock uses semantic asset key",
    '"falling_rock"'
    in (ROOT / "scripts/hazards/falling_rock.gd").read_text()
    and '"rotating_gear"'
    not in (ROOT / "scripts/hazards/falling_rock.gd").read_text(),
)


prologue_text = (ROOT / "scripts/levels/prologue_forest.gd").read_text()
cinematic_text = (ROOT / "scripts/cutscenes/prologue_cinematic.gd").read_text()
seal_text = (ROOT / "scripts/interactables/ancient_seal.gd").read_text()
football_text = (ROOT / "scripts/interactables/football.gd").read_text()
check(
    "prologue uses cinematic state machine",
    "enum SequenceState" in prologue_text
    and "SequenceState.PLAYER_CONTROL" in prologue_text
    and "func _run_intro_cinematic" in prologue_text
    and "transition_started" in prologue_text,
)
check(
    "interactive football tutorial removed",
    "TargetZone" not in prologue_text
    and "can_activate_target" not in prologue_text
    and "_ball_kicked" not in prologue_text
    and "Press E to pull" not in prologue_text,
)
check(
    "cinematic owns scripted football and character motion",
    "football.set_cinematic_control(true)" in cinematic_text
    and 'tween_property(\n        football, "global_position"' in cinematic_text
    and 'arin.play_cinematic_animation("kick")' in cinematic_text
    and 'niko.play_state("fall")' in cinematic_text,
)
check(
    "first gameplay control begins after Astra dialogue",
    "func _begin_player_control" in cinematic_text
    and 'level.set_objective("Kick the Ancient Seal")' in cinematic_text
    and "seal.set_kick_enabled(true)" in cinematic_text
    and "EventBus.cutscene_ended.emit()" in cinematic_text,
)
check(
    "seal remains gated until cinematic completion",
    "seal.interaction_enabled = false" in prologue_text
    and "seal.kick_enabled = false" in prologue_text
    and "func can_kick_seal" in prologue_text
    and "seal.set_hand_attempted(true)" in cinematic_text
    and "kick_receiver.set_detection_enabled" in seal_text,
)
check(
    "football physics cannot block cinematic story",
    "var cinematic_controlled := false" in football_text
    and "if cinematic_controlled:" in football_text
    and "collision_layer = 0 if active" in football_text,
)
check(
    "prologue completion continues through existing level flow",
    "complete_level()" in prologue_text
    and "_load_level(current_level_index + 1)" in main_text,
)

enemy_text = (ROOT / "scripts/enemies/enemy_base.gd").read_text()
level_three_text = (ROOT / "scripts/levels/level_03_guardian_court.gd").read_text()
jar_text = (ROOT / "scripts/interactables/rune_jar.gd").read_text()
pillar_text = (ROOT / "scripts/environment/breakable_pillar.gd").read_text()
projectile_text = (ROOT / "scripts/enemies/reflectable_projectile.gd").read_text()
check(
    "enemy combat effects require ACTIVE world",
    "func can_receive_combat_effects" in enemy_text
    and enemy_text.count("if not can_receive_combat_effects()") >= 5
    and "if not world_active:" in enemy_text,
)
check(
    "Level 3 defeat and wave guards",
    "func can_process_enemy_defeat" in level_three_text
    and "if not can_process_enemy_defeat(enemy):" in level_three_text
    and "wave_advancing" in level_three_text
    and "gatekeeper_spawned" in level_three_text,
)
check(
    "Level 3 Kickoff activates combat once",
    "func can_start_arena" in level_three_text
    and "if not can_start_arena():" in level_three_text
    and "_set_combat_world_active(true)" in level_three_text
    and "bell.collision_layer = 0" in level_three_text,
)
check(
    "Rune Jar frozen guard",
    "var world_active := false" in jar_text
    and "func set_world_active" in jar_text
    and jar_text.count("if not world_active") >= 3,
)
check(
    "Breakable Pillar frozen guard",
    "var world_active := false" in pillar_text
    and "func set_world_active" in pillar_text
    and "if not world_active or broken_once" in pillar_text,
)
check(
    "Suspended projectile is harmless while frozen",
    "configure_suspended" in projectile_text
    and "_set_collision_enabled(false)" in projectile_text
    and "if not active or not reflectable" in projectile_text,
)

hud_text = (ROOT / "scripts/ui/game_hud.gd").read_text()
check(
    "central dialogue queue exists",
    "var dialogue_queue: Array[Dictionary]" in hud_text
    and "func _process_dialogue_queue" in hud_text
    and "dialogue_queue.pop_front()" in hud_text
    and "if dialogue_running:" in hud_text,
)
check(
    "dialogue queue auto advances and clears safely",
    "func clear_dialogue_queue" in hud_text
    and "dialogue_generation += 1" in hud_text
    and "elapsed < duration" in hud_text
    and "dialogue_queue.pop_front()" in hud_text,
)
check(
    "dialogue sequences support player lock restore",
    "func show_dialogue_sequence" in hud_text
    and "EventBus.cutscene_started.emit()" in hud_text
    and "EventBus.cutscene_ended.emit()" in hud_text,
)
check(
    "story dialogue manual advance disabled",
    "var manual_dialogue_advance_enabled := false" in hud_text
    and "if not manual_dialogue_advance_enabled:" in hud_text,
)
check(
    "dialogue active state blocks gameplay",
    "var dialogue_active: bool = false" in state_text
    and "func is_gameplay_input_blocked" in state_text
    and "GameState.is_gameplay_input_blocked()"
    in (ROOT / "scripts/characters/arin.gd").read_text(),
)
check(
    "dialogue lock remains active for full queue",
    "GameState.set_dialogue_active(true)" in hud_text
    and "GameState.set_dialogue_active(false)" in hud_text
    and "while token == dialogue_generation and not dialogue_queue.is_empty()"
    in hud_text,
)
check(
    "dialogue interruption clears shared state",
    "signal dialogue_clear_requested"
    in (ROOT / "autoload/event_bus.gd").read_text()
    and "EventBus.dialogue_clear_requested.emit()" in main_text
    and "GameState.clear_dialogue_state(true)" in main_text,
)
automatic_dialogue_test_text = (
    ROOT / "tests/automatic_dialogue_test.gd"
).read_text()
check(
    "automatic dialogue regression coverage",
    all(token in automatic_dialogue_test_text for token in [
        "Automatic dialogue did not preserve line order",
        "Manual dialogue advance is unexpectedly enabled",
        "Clearing dialogue left active or pending lines",
    ]),
)
cinematic_test_text = (ROOT / "tests/prologue_cinematic_test.gd").read_text()
check(
    "prologue cinematic regression coverage",
    all(token in cinematic_test_text for token in [
        "Player input was not locked at intro start",
        "Football is not under scripted cinematic control",
        "Ancient Seal is not kickable at gameplay start",
        "Prologue completion did not emit exactly once",
    ]),
)

check(
    "required story dialogue remains present",
    all(
        line in "\n".join(
            path.read_text(errors="replace")
            for path in ROOT.rglob("*.gd")
        )
        for line in [
            "Pass it here, Arin!",
            "One motion reclaimed. Three remain.",
            "Don't trust everything it shows you.",
            "That isn't the same answer.",
            "But every first strike gives me motion.",
            "A false beginning feeds me.",
            "No promises.",
        ]
    ),
)

bad_artifacts: list[str] = []
for path in ROOT.rglob("*"):
    if (
        path.name in {".godot", ".import", "__pycache__"}
        or path.suffix in {".tmp", ".bak"}
        or path.name.endswith("~")
    ):
        bad_artifacts.append(str(path.relative_to(ROOT)))
check("no cache/temp artifacts", not bad_artifacts, ", ".join(bad_artifacts))

export_text = (ROOT / "export_presets.cfg").read_text()
check(
    "Windows export preset",
    'name="Windows Desktop"' in export_text
    and "build/windows/TheFirstKick.exe" in export_text,
)
check(
    "Web export preset",
    'name="Web"' in export_text and "build/web/index.html" in export_text,
)

script_count = sum(1 for _ in ROOT.rglob("*.gd"))
scene_count = sum(1 for _ in ROOT.rglob("*.tscn"))
report = [
    "STATIC VALIDATION REPORT",
    "========================",
    f"Scripts: {script_count}",
    f"Scenes: {scene_count}",
    f"Asset manifest entries: {len(asset)}",
    f"Checks executed: {len(checks)}",
    f"Static errors: {len(errors)}",
    f"Warnings: {len(warnings)}",
    "",
]
for name, passed, detail in checks:
    report.append(f"[PASS] {name}" if passed else f"[FAIL] {name}: {detail}")
if errors:
    report.extend(["", "ERRORS", *[f"- {error}" for error in errors]])
if warnings:
    report.extend(["", "WARNINGS", *[f"- {warning}" for warning in warnings]])
(ROOT / "STATIC_VALIDATION_REPORT.txt").write_text("\n".join(report) + "\n")
print("\n".join(report[:8]))
if errors:
    for error in errors:
        print(error)
    sys.exit(1)
