extends SceneTree

var failures: Array[String] = []
var hud: GameHUD
var arin: ArinController
var started_lines: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    hud = GameHUD.new()
    get_root().add_child(hud)
    var packed := load("res://scenes/characters/arin.tscn") as PackedScene
    arin = packed.instantiate() as ArinController
    get_root().add_child(arin)
    arin.set_physics_process(false)
    await process_frame
    hud.dialogue_line_started.connect(
        func(_speaker: String, text: String) -> void:
            started_lines.append(text)
    )

    hud.queue_dialogue("A", "First", 0.08)
    hud.queue_dialogue("B", "Second", 0.08)
    await _wait_for_current("First")
    if not arin._gameplay_input_blocked():
        failures.append("Gameplay input is not blocked during dialogue")

    for event in [_key_event(KEY_SPACE), _key_event(KEY_E), _mouse_event()]:
        hud._input(event)
        arin._unhandled_input(event)
        await process_frame
    if str(hud.current_dialogue.get("text", "")) != "First":
        failures.append("Manual input advanced automatic story dialogue")
    if arin.attacking:
        failures.append("Dialogue input triggered a gameplay kick")

    await _wait_for_queue_end()
    if started_lines != ["First", "Second"]:
        failures.append("Automatic dialogue order changed")
    if GameState.dialogue_active:
        failures.append("Dialogue state remained active after auto finish")

    hud.queue_free()
    arin.queue_free()
    await process_frame
    _finish()

func _key_event(key: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = key
    event.physical_keycode = key
    event.pressed = true
    return event

func _mouse_event() -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    return event

func _wait_for_current(text: String) -> void:
    for _frame in 300:
        if str(hud.current_dialogue.get("text", "")) == text:
            return
        await process_frame
    failures.append("Dialogue line did not become current: " + text)

func _wait_for_queue_end() -> void:
    for _frame in 600:
        if not hud.has_pending_dialogue():
            return
        await process_frame
    failures.append("Dialogue queue did not finish automatically")

func _finish() -> void:
    if failures.is_empty():
        print("dialogue_input_safety_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("dialogue_input_safety_test: FAIL (%d)" % failures.size())
    quit(1)
