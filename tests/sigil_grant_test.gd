extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    GameState.reset_run()
    if not GameState.add_sigil("time"):
        failures.append("First TIME Sigil grant should succeed")
    if GameState.add_sigil("time"):
        failures.append("Duplicate TIME Sigil grant should be rejected")
    if GameState.sigil_count() != 1:
        failures.append("Duplicate Sigil changed the collected count")
    if not GameState.mark_level_completed("level_01"):
        failures.append("First level completion mark should succeed")
    if GameState.mark_level_completed("level_01"):
        failures.append("Duplicate level completion mark should be rejected")
    if not GameState.add_sigil("echo"):
        failures.append("ECHO Sigil grant should succeed")
    if not GameState.add_sigil("force"):
        failures.append("FORCE Sigil grant should succeed")
    if not GameState.add_sigil("truth"):
        failures.append("TRUTH Sigil grant should succeed")
    if not GameState.has_all_sigils():
        failures.append("All four unique Sigils should satisfy final-box gate")
    GameState.reset_run()
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("sigil_grant_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("sigil_grant_test: FAIL (%d)" % failures.size())
    quit(1)
