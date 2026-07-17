extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var level := SealedHeart.new()
    var selected_positions: Dictionary = {}
    for seed_value in range(1, 41):
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_value
        var selected := level.select_real_niko_index(3, rng)
        if selected < 0 or selected >= 3:
            failures.append("Selected Niko index is outside 0..2")
            continue
        selected_positions[selected] = true
        var real_count := 0
        for index in 3:
            if index == selected:
                real_count += 1
        if real_count != 1:
            failures.append("Selection did not produce exactly one real Niko")
    if selected_positions.size() < 2:
        failures.append("Controlled seeds did not select multiple positions")

    var stable_rng := RandomNumberGenerator.new()
    stable_rng.seed = 20260714
    level.real_niko_index = level.select_real_niko_index(3, stable_rng)
    var stable_value := level.real_niko_index
    for _frame in 20:
        if level.real_niko_index != stable_value:
            failures.append("Real Niko index changed during one attempt")
            break

    level.free()
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("final_niko_randomization_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("final_niko_randomization_test: FAIL (%d)" % failures.size())
    quit(1)
