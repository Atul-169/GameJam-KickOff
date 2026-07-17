extends SceneTree

class SpawnHarness:
    extends LevelManager

    func _init() -> void:
        level_id = "spawn_position_test"
        world_width = 1200.0
        world_height = 900.0
        checkpoint_position = Vector2(80, 700)
        use_default_floor = false

    func build_level() -> void:
        return

var failures: Array[String] = []
var harness: SpawnHarness

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    harness = SpawnHarness.new()
    get_root().add_child(harness)
    await process_frame
    _test_moving_platform()
    _test_echo_orb()
    _test_exit_gate()
    _test_shortcut_lift()
    harness.queue_free()
    await process_frame
    _finish()

func _test_moving_platform() -> void:
    var expected := Vector2(310, 420)
    var node := harness.spawn_scene(
        "res://scenes/environment/moving_platform.tscn", expected
    ) as MovingPlatform
    _check_vector("MovingPlatform inserted position", node.position, expected)
    _check_vector("MovingPlatform captured start", node.start_position, expected)
    node.position += Vector2(200, 90)
    node.reset_state()
    _check_vector("MovingPlatform reset position", node.position, expected)

func _test_echo_orb() -> void:
    var expected := Vector2(540, 360)
    var node := harness.spawn_scene(
        "res://scenes/interactables/echo_orb.tscn", expected
    ) as EchoOrb
    _check_vector("EchoOrb inserted position", node.position, expected)
    _check_vector("EchoOrb captured spawn", node.spawn_position, expected)
    node.global_position += Vector2(180, 120)
    node.reset_state()
    _check_vector("EchoOrb reset position", node.global_position, expected)

func _test_exit_gate() -> void:
    var expected := Vector2(760, 300)
    var node := harness.spawn_scene(
        "res://scenes/interactables/exit_gate.tscn", expected
    ) as ExitGate
    _check_vector("ExitGate inserted position", node.position, expected)
    _check_vector("ExitGate captured open position", node.open_position, expected)
    node.set_closure(1.0)
    node.reset_state()
    _check_vector("ExitGate reset position", node.position, expected)

func _test_shortcut_lift() -> void:
    var expected := Vector2(880, 680)
    var node := harness.spawn_scene(
        "res://scenes/environment/shortcut_lift.tscn", expected
    ) as ShortcutLift
    _check_vector("ShortcutLift inserted position", node.position, expected)
    _check_vector("ShortcutLift captured start", node.start_position, expected)
    node.position += Vector2(0, -300)
    node.reset_state()
    _check_vector("ShortcutLift reset position", node.position, expected)

func _check_vector(label: String, actual: Vector2, expected: Vector2) -> void:
    if not actual.is_equal_approx(expected):
        failures.append("%s: expected %s, got %s" % [label, expected, actual])

func _finish() -> void:
    if failures.is_empty():
        print("spawn_position_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("spawn_position_test: FAIL (%d)" % failures.size())
    quit(1)
