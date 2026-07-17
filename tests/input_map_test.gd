extends SceneTree

const REQUIRED_INPUTS: Array[String] = [
    "move_left", "move_right", "jump", "kick", "charged_kick",
    "interact", "restart", "pause",
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for action in REQUIRED_INPUTS:
        if not InputMap.has_action(action):
            failures.append("Missing input action: " + action)
            continue
        if InputMap.action_get_events(action).is_empty():
            failures.append("Input action has no persistent events: " + action)
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("input_map_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("input_map_test: FAIL (%d)" % failures.size())
    quit(1)
