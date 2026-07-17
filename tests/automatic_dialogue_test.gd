extends SceneTree

var failures: Array[String] = []
var hud: GameHUD
var started_lines: Array[String] = []
var finished_count := 0
var cutscene_started_count := 0
var cutscene_ended_count := 0
var lock_seen_during_line := false

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    hud = GameHUD.new()
    get_root().add_child(hud)
    await process_frame
    hud.dialogue_line_started.connect(_on_line_started)
    hud.dialogue_queue_finished.connect(_on_queue_finished)
    EventBus.cutscene_started.connect(_on_cutscene_started)
    EventBus.cutscene_ended.connect(_on_cutscene_ended)

    await _test_auto_order_and_lock()
    await _test_manual_input_not_required()
    await _test_clear_cleanup()

    hud.queue_free()
    await process_frame
    _finish()

func _test_auto_order_and_lock() -> void:
    started_lines.clear()
    finished_count = 0
    lock_seen_during_line = false
    var completed: bool = await hud.show_dialogue_sequence(
        [
            {"speaker": "A", "text": "One", "duration": 0.04},
            {"speaker": "B", "text": "Two", "duration": 0.04},
            {"speaker": "C", "text": "Three", "duration": 0.04},
        ],
        true
    )
    if not completed:
        failures.append("Automatic dialogue sequence was interrupted")
    if not lock_seen_during_line:
        failures.append("Dialogue did not lock gameplay while a line was visible")
    await _wait_for_queue_finish()
    if started_lines != ["One", "Two", "Three"]:
        failures.append("Automatic dialogue did not preserve line order")
    if GameState.dialogue_active:
        failures.append("Dialogue lock remained after the full queue")
    if cutscene_started_count != 1 or cutscene_ended_count != 1:
        failures.append("Locked automatic sequence did not restore input once")

func _test_manual_input_not_required() -> void:
    started_lines.clear()
    finished_count = 0
    hud.queue_dialogue("AUTO", "No input", 0.06)
    await process_frame
    var key_event := InputEventKey.new()
    key_event.keycode = KEY_E
    key_event.pressed = true
    hud._input(key_event)
    await _wait_for_queue_finish()
    if started_lines != ["No input"]:
        failures.append("Automatic line did not finish without player input")
    if hud.manual_dialogue_advance_enabled:
        failures.append("Manual dialogue advance is unexpectedly enabled")

func _test_clear_cleanup() -> void:
    hud.queue_dialogue("A", "Interrupted", 5.0)
    hud.queue_dialogue("B", "Pending", 5.0)
    await process_frame
    hud.clear_dialogue_queue()
    await process_frame
    if hud.has_pending_dialogue() or GameState.dialogue_active:
        failures.append("Clearing dialogue left active or pending lines")

func _on_line_started(_speaker: String, text: String) -> void:
    started_lines.append(text)
    if GameState.dialogue_active:
        lock_seen_during_line = true

func _on_queue_finished() -> void:
    finished_count += 1

func _on_cutscene_started() -> void:
    cutscene_started_count += 1

func _on_cutscene_ended() -> void:
    cutscene_ended_count += 1

func _wait_for_queue_finish() -> void:
    for _frame in 600:
        if finished_count > 0 and not hud.has_pending_dialogue():
            return
        await process_frame
    failures.append("Automatic dialogue queue did not finish")

func _finish() -> void:
    if EventBus.cutscene_started.is_connected(_on_cutscene_started):
        EventBus.cutscene_started.disconnect(_on_cutscene_started)
    if EventBus.cutscene_ended.is_connected(_on_cutscene_ended):
        EventBus.cutscene_ended.disconnect(_on_cutscene_ended)
    if failures.is_empty():
        print("automatic_dialogue_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("automatic_dialogue_test: FAIL (%d)" % failures.size())
    quit(1)
