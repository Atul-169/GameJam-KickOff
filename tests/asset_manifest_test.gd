extends SceneTree

const VISUAL_KEYS: Array[String] = [
    "arin_idle", "arin_run", "arin_jump", "arin_fall", "arin_kick",
    "arin_charged_kick", "arin_push_fail", "arin_hurt",
    "arin_knockout", "arin_victory", "arin_portrait", "astra",
    "niko_idle", "niko_run", "niko_fall", "niko_trapped",
    "niko_rescue", "niko_portrait", "football", "gear_pedestal",
    "time_relay", "kick_switch_off", "kick_switch_on", "echo_orb",
    "kickoff_bell", "final_seal", "final_box", "exit_gate",
    "rune_jar", "echo_timed_gate", "echo_seal_lock", "weak_platform", "shortcut_lift", "rotating_gear",
    "falling_rock", "echo_cracked_wall", "breakable_pillar", "sigil_time", "sigil_echo", "sigil_force",
    "sigil_truth", "stone_guardian", "arc_guardian", "echo_shade",
    "shadow_hunter", "echo_warden", "gatekeeper", "keeper", "logo",
    "button_normal", "button_hover", "button_pressed", "panel",
    "health_full", "health_empty", "kick_icon", "charged_kick_icon",
    "dialogue_box", "objective_panel", "timer_panel", "kick_flash",
    "charged_kick_flash", "projectile_trail", "rune_activation",
    "dust", "shadow_spawn", "boss_core",
]
const AUDIO_KEYS: Array[String] = [
    "main_menu_music", "forest_music", "gear_hall_music",
    "echo_archive_music", "guardian_combat_music", "final_boss_music",
    "ending_music", "kick_sfx", "charged_kick_sfx", "jump_sfx",
    "hurt_sfx", "rune_sfx", "gear_sfx", "rock_fall_sfx",
    "projectile_reflect_sfx", "gate_open_sfx", "kickoff_sfx",
    "boss_hit_sfx", "level_complete_sfx",
]
const FONT_KEYS: Array[String] = ["main_font"]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var manifest := _read_manifest()
    if manifest.is_empty():
        _finish()
        return
    for key: Variant in manifest.keys():
        if not manifest[key] is String:
            failures.append("Non-string asset path: " + str(key))
    _validate_extensions(manifest, VISUAL_KEYS, [".png", ".svg", ".webp"])
    _validate_extensions(manifest, AUDIO_KEYS, [".wav", ".ogg", ".mp3"])
    _validate_extensions(manifest, FONT_KEYS, [".ttf", ".otf", ".woff", ".woff2"])
    if manifest.get("falling_rock", "") != "res://assets/environment/falling_rock.png":
        failures.append("falling_rock path is missing or incorrect")
    if manifest.get("rotating_gear", "") == manifest.get("falling_rock", ""):
        failures.append("falling_rock and rotating_gear must use separate assets")
    if manifest.get("astra", "") != "res://assets/characters/astra/astra.png":
        failures.append("astra path is missing or incorrect")
    _finish()

func _read_manifest() -> Dictionary:
    var path := "res://resources/asset_manifest.json"
    if not FileAccess.file_exists(path):
        failures.append("Missing asset manifest")
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        failures.append("Cannot open asset manifest")
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        failures.append("Asset manifest is not a Dictionary")
        return {}
    return parsed as Dictionary

func _validate_extensions(
    manifest: Dictionary, keys: Array[String], extensions: Array[String]
) -> void:
    for key in keys:
        if not manifest.has(key):
            failures.append("Missing asset key: " + key)
            continue
        var asset_path := str(manifest[key]).to_lower()
        var valid := false
        for extension in extensions:
            if asset_path.ends_with(extension):
                valid = true
                break
        if not valid:
            failures.append("Invalid extension for %s: %s" % [key, asset_path])

func _finish() -> void:
    if failures.is_empty():
        print("asset_manifest_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("asset_manifest_test: FAIL (%d)" % failures.size())
    quit(1)
