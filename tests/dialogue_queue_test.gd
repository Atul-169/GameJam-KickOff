extends SceneTree

var failures: Array[String] = []
var hud: GameHUD
var started_lines: Array[String] = []
var queue_finished_count := 0
var cutscene_started_count := 0
var cutscene_ended_count := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    hud = GameHUD.new()
    get_root().add_child(hud)
    await process_frame
    hud.dialogue_line_started.connect(_line_started)
    hud.dialogue_queue_finished.connect(
        func() -> void: queue_finished_count += 1
    )
    EventBus.cutscene_started.connect(
        func() -> void: cutscene_started_count += 1
    )
    EventBus.cutscene_ended.connect(
        func() -> void: cutscene_ended_count += 1
    )
    await _test_order_and_single_processor()
    await _test_manual_advance()
    await _test_clear_and_lock_restore()
    hud.queue_free()
    await process_frame
    _finish()

func _line_started(speaker: String, text: String) -> void:
    started_lines.append("%s:%s" % [speaker, text])

func _test_order_and_single_processor() -> void:
    started_lines.clear()
    queue_finished_count = 0
    var starts_before := hud.dialogue_processor_start_count
    hud.queue_dialogue("A", "One", 0.04)
    hud.queue_dialogue("B", "Two", 0.04)
    hud.queue_dialogue("C", "Three", 0.04)
    await _wait_for_queue_finish()
    var expected: Array[String] = ["A:One", "B:Two", "C:Three"]
    if started_lines != expected:
        failures.append("Dialogue lines did not preserve queue order")
    if hud.dialogue_processor_start_count - starts_before != 1:
        failures.append("More than one dialogue queue processor started")

func _test_manual_advance() -> void:
    queue_finished_count = 0
    hud.queue_dialogue("NIKO", "Manual", 5.0)
    await process_frame
    await process_frame
    if hud.current_dialogue.is_empty():
        failures.append("Manual-advance line never became current")
        return
    hud.request_dialogue_advance()
    await _wait_for_queue_finish()
    if hud.has_pending_dialogue():
        failures.append("Manual advance did not finish the current line")

func _test_clear_and_lock_restore() -> void:
    queue_finished_count = 0
    hud.queue_dialogue("A", "Long", 5.0)
    hud.queue_dialogue("B", "Pending", 5.0)
    await process_frame
    hud.clear_dialogue_queue()
    await process_frame
    if hud.has_pending_dialogue() or hud.dialogue_panel.visible:
        failures.append("Clearing dialogue left active or pending lines")

    var starts_before := cutscene_started_count
    var ends_before := cutscene_ended_count
    queue_finished_count = 0
    hud.show_dialogue_sequence(
        [
            {"speaker": "ASTRA", "text": "Locked", "duration": 0.04},
            {"speaker": "ARIN", "text": "Restored", "duration": 0.04},
        ],
        true,
    )
    await _wait_for_queue_finish()
    if cutscene_started_count - starts_before != 1:
        failures.append("Locked sequence did not emit one cutscene start")
    if cutscene_ended_count - ends_before != 1:
        failures.append("Locked sequence did not restore controls once")

func _wait_for_queue_finish() -> void:
    for _frame in 600:
        if queue_finished_count > 0 and not hud.has_pending_dialogue():
            return
        await process_frame
    failures.append("Dialogue queue did not finish within the test window")

func _finish() -> void:
    if failures.is_empty():
        print("dialogue_queue_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("dialogue_queue_test: FAIL (%d)" % failures.size())
    quit(1)
