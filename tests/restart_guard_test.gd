extends SceneTree

var failures: Array[String] = []
var main_controller: Node
var level: LevelManager

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var script := load("res://scripts/core/main.gd") as Script
    main_controller = script.new()
    level = LevelManager.new()
    main_controller.current_level = level
    main_controller.current_level_index = 1

    _set_state(false, false, false, false)
    _expect(true, "ACTIVE should allow restart")

    level.failed = true
    _expect(true, "FAILED should allow restart")
    level.failed = false

    level.completed = true
    _expect(false, "COMPLETED should block restart")
    level.completed = false

    main_controller.results_open = true
    _expect(false, "Results screen should block restart")
    main_controller.results_open = false

    main_controller.transition_in_progress = true
    _expect(false, "Transition should block restart")
    main_controller.transition_in_progress = false

    level.restart_blocked = true
    _expect(false, "Completion cutscene guard should block restart")

    main_controller.free()
    level.free()
    _finish()

func _set_state(
    completed: bool,
    results_visible: bool,
    transition_active: bool,
    blocked: bool
) -> void:
    level.completed = completed
    level.failed = false
    level.restart_blocked = blocked
    main_controller.results_open = results_visible
    main_controller.transition_in_progress = transition_active

func _expect(expected: bool, message: String) -> void:
    if main_controller.can_restart_current_level() != expected:
        failures.append(message)

func _finish() -> void:
    if failures.is_empty():
        print("restart_guard_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("restart_guard_test: FAIL (%d)" % failures.size())
    quit(1)
