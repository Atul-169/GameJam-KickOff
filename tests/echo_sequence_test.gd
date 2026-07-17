extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _test_valid_sequence()
    _test_wrong_after_ear()
    _test_wrong_then_full_sequence()
    _finish()

func _test_valid_sequence() -> void:
    var tracker := EchoSequenceTracker.new()
    tracker.configure(["EAR", "EYE", "MOUTH"])
    tracker.register("EAR")
    tracker.register("EYE")
    var result := tracker.register("MOUTH")
    if result != EchoSequenceTracker.Result.COMPLETED or not tracker.solved:
        failures.append("EAR → EYE → MOUTH did not solve the sequence")

func _test_wrong_after_ear() -> void:
    var tracker := EchoSequenceTracker.new()
    tracker.configure(["EAR", "EYE", "MOUTH"])
    tracker.register("EAR")
    var wrong_result := tracker.register("MOUTH")
    if wrong_result != EchoSequenceTracker.Result.WRONG:
        failures.append("Wrong rune after EAR was not rejected")
    if tracker.progress != 0 or tracker.solved:
        failures.append("Wrong rune did not clear sequence progress")
    tracker.register("EYE")
    tracker.register("MOUTH")
    if tracker.solved:
        failures.append("EAR → wrong → EYE → MOUTH incorrectly solved")

func _test_wrong_then_full_sequence() -> void:
    var tracker := EchoSequenceTracker.new()
    tracker.configure(["EAR", "EYE", "MOUTH"])
    tracker.register("FLAME")
    if tracker.progress != 0:
        failures.append("Initial wrong rune did not leave progress at zero")
    tracker.register("EAR")
    tracker.register("EYE")
    tracker.register("MOUTH")
    if not tracker.solved:
        failures.append("Full valid order after a wrong rune did not solve")

func _finish() -> void:
    if failures.is_empty():
        print("echo_sequence_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("echo_sequence_test: FAIL (%d)" % failures.size())
    quit(1)
