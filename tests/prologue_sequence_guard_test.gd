extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var level := PrologueForest.new()
    level.reset_sequence_flags()
    if level.sequence_state != PrologueForest.SequenceState.INTRO_START:
        failures.append("Prologue did not reset to INTRO_START")
    if level.can_kick_seal():
        failures.append("Seal can be kicked before cinematic completion")
    level.sequence_state = PrologueForest.SequenceState.ASTRA_DIALOGUE
    if level.can_kick_seal():
        failures.append("Seal can be kicked during Astra dialogue")
    level.transition_started = true
    level.reset_sequence_flags()
    if level.transition_started:
        failures.append("Prologue reset left transition guard active")
    level.free()
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("prologue_sequence_guard_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("prologue_sequence_guard_test: FAIL (%d)" % failures.size())
    quit(1)
