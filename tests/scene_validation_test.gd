extends SceneTree

const REQUIRED_INPUTS: Array[String] = [
    "move_left", "move_right", "jump", "kick", "charged_kick",
    "interact", "restart", "pause",
]
const REQUIRED_AUTOLOAD_FILES: Array[String] = [
    "res://autoload/event_bus.gd",
    "res://autoload/game_state.gd",
    "res://autoload/scene_manager.gd",
    "res://autoload/audio_manager.gd",
    "res://autoload/asset_registry.gd",
]
const REQUIRED_ANIMATIONS: Array[String] = [
    "idle", "run", "jump", "fall", "kick", "charged_kick",
    "push_fail", "hurt", "knockout", "victory",
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for action in REQUIRED_INPUTS:
        if not InputMap.has_action(action):
            failures.append("Missing input action: " + action)
    for path in REQUIRED_AUTOLOAD_FILES:
        if not FileAccess.file_exists(path):
            failures.append("Missing autoload script: " + path)
    _validate_animation_manifest()
    _finish()

func _validate_animation_manifest() -> void:
    var path := "res://resources/animation_manifest.json"
    if not FileAccess.file_exists(path):
        failures.append("Missing animation manifest")
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        failures.append("Cannot open animation manifest")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        failures.append("Animation manifest is not a Dictionary")
        return
    var root := parsed as Dictionary
    var arin: Dictionary = root.get("arin", {})
    for animation_name in REQUIRED_ANIMATIONS:
        if not arin.has(animation_name):
            failures.append("Missing Arin animation: " + animation_name)

func _finish() -> void:
    if failures.is_empty():
        print("scene_validation_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("scene_validation_test: FAIL (%d)" % failures.size())
    quit(1)
