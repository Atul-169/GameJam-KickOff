extends SceneTree

var failures: Array[String] = []
var completion_count := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    Engine.time_scale = 20.0
    var packed := load("res://scenes/levels/prologue_forest.tscn") as PackedScene
    if packed == null:
        failures.append("Unable to load prologue scene")
        _finish()
        return
    var level := packed.instantiate() as PrologueForest
    if level == null:
        failures.append("Prologue root is not PrologueForest")
        _finish()
        return
    level.cinematic_duration_scale = 0.02
    get_root().add_child(level)
    EventBus.level_completed.connect(_on_level_completed)
    await process_frame

    if level.sequence_state == PrologueForest.SequenceState.PLAYER_CONTROL:
        failures.append("Player control began before the cinematic ran")
    if level.player == null or not level.player.input_locked:
        failures.append("Player input was not locked at intro start")
    if level.football == null or not level.football.cinematic_controlled:
        failures.append("Football is not under scripted cinematic control")
    if _contains_target_zone(level):
        failures.append("Obsolete football tutorial target zones still exist")

    await _wait_for_player_control(level)
    if level.sequence_state != PrologueForest.SequenceState.PLAYER_CONTROL:
        failures.append("Cinematic did not reach PLAYER_CONTROL")
    if level.player.input_locked:
        failures.append("Player input did not unlock after Astra dialogue")
    if not level.seal.can_receive_kick():
        failures.append("Ancient Seal is not kickable at gameplay start")
    if level.hud.objective_label.text.find("Kick the Ancient Seal") < 0:
        failures.append("Gameplay objective was not set after Astra dialogue")
    if level.astra_visual == null or not is_instance_valid(level.astra_visual):
        failures.append("Astra did not remain visible at gameplay start")

    level.seal.kick_receiver.receive_kick(
        500.0, 1, Vector2.RIGHT, false, level.player
    )
    await _wait_for_completion()
    if completion_count != 1:
        failures.append("Prologue completion did not emit exactly once")

    level.queue_free()
    await process_frame
    Engine.time_scale = 1.0
    _finish()


func _contains_target_zone(root_node: Node) -> bool:
    for child in root_node.get_children():
        if child is TargetZone or _contains_target_zone(child):
            return true
    return false

func _wait_for_player_control(level: PrologueForest) -> void:
    for _frame in 1800:
        if (
            is_instance_valid(level)
            and level.sequence_state == PrologueForest.SequenceState.PLAYER_CONTROL
        ):
            return
        await process_frame
    failures.append("Timed out waiting for cinematic gameplay start")

func _wait_for_completion() -> void:
    for _frame in 900:
        if completion_count > 0:
            return
        await process_frame
    failures.append("Timed out waiting for prologue completion")

func _on_level_completed(id: String) -> void:
    if id == "prologue":
        completion_count += 1

func _finish() -> void:
    Engine.time_scale = 1.0
    if EventBus.level_completed.is_connected(_on_level_completed):
        EventBus.level_completed.disconnect(_on_level_completed)
    if failures.is_empty():
        print("prologue_cinematic_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("prologue_cinematic_test: FAIL (%d)" % failures.size())
    quit(1)
