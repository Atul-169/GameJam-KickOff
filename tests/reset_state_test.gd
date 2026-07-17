extends SceneTree

var failures: Array[String] = []
var container: Node2D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    container = Node2D.new()
    get_root().add_child(container)
    _test_game_state_reset()
    _test_trap_reset()
    _test_final_box_reset()
    _test_falling_rock_reset()
    container.queue_free()
    _finish()

func _test_game_state_reset() -> void:
    GameState.add_sigil("time")
    GameState.damage_taken = 9
    GameState.mistakes = 7
    GameState.escape_checkpoint = true
    GameState.reset_run()
    if GameState.sigil_count() != 0:
        failures.append("GameState reset did not clear Sigils")
    if GameState.damage_taken != 0 or GameState.mistakes != 0:
        failures.append("GameState reset did not clear run statistics")
    if GameState.escape_checkpoint:
        failures.append("GameState reset did not clear escape checkpoint")

func _test_trap_reset() -> void:
    var trap := KeeperTrap.new()
    container.add_child(trap)
    trap.global_position = Vector2.ZERO
    if not trap.try_break(Vector2.ZERO, Vector2.ZERO, true, 1):
        failures.append("Keeper trap setup did not break")
    trap.reset_state()
    if trap.broken_once or trap.last_attack_id != -1:
        failures.append("Keeper trap reset did not restore defaults")

func _test_final_box_reset() -> void:
    var packed := load("res://scenes/interactables/final_box.tscn") as PackedScene
    var box := packed.instantiate() as FinalBox
    container.add_child(box)
    box.set_enabled(true)
    box.finished = true
    box.reset_state()
    if box.enabled or box.finished:
        failures.append("Final Box reset did not restore locked state")

func _test_falling_rock_reset() -> void:
    var packed := load("res://scenes/hazards/falling_rock.tscn") as PackedScene
    var rock := packed.instantiate() as FallingRock
    container.add_child(rock)
    rock.active = true
    rock.running = true
    rock.rock.position.y = 200.0
    rock.reset_state()
    if rock.active or rock.running or rock.rock.position != Vector2.ZERO:
        failures.append("Falling rock reset did not restore defaults")

func _finish() -> void:
    if failures.is_empty():
        print("reset_state_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("reset_state_test: FAIL (%d)" % failures.size())
    quit(1)
