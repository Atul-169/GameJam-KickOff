extends SceneTree

const REQUIRED: Dictionary = {
    "arin": [
        "idle", "run", "jump", "fall", "kick", "charged_kick",
        "push_fail", "hurt", "knockout", "victory",
    ],
    "niko": ["idle", "run", "fall", "trapped", "rescue"],
}

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var path := "res://resources/animation_manifest.json"
    if not FileAccess.file_exists(path):
        failures.append("Missing animation manifest")
        _finish()
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        failures.append("Cannot open animation manifest")
        _finish()
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        failures.append("Animation manifest is not a Dictionary")
        _finish()
        return
    var root := parsed as Dictionary
    for actor: String in REQUIRED.keys():
        var actor_data: Dictionary = root.get(actor, {})
        if actor_data.is_empty():
            failures.append("Missing actor animation section: " + actor)
            continue
        for animation_name: String in REQUIRED[actor]:
            if not actor_data.has(animation_name):
                failures.append("Missing animation: %s/%s" % [actor, animation_name])
                continue
            var config: Dictionary = actor_data[animation_name]
            if int(config.get("frames", 0)) <= 0:
                failures.append("Invalid frame count: %s/%s" % [actor, animation_name])
            if float(config.get("fps", 0.0)) <= 0.0:
                failures.append("Invalid FPS: %s/%s" % [actor, animation_name])
            if str(config.get("asset_key", "")).is_empty():
                failures.append("Missing asset key: %s/%s" % [actor, animation_name])
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("animation_manifest_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("animation_manifest_test: FAIL (%d)" % failures.size())
    quit(1)
