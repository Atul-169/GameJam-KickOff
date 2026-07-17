extends SceneTree

var failures: Array[String] = []
var container: Node2D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    container = Node2D.new()
    get_root().add_child(container)
    var packed := load("res://scenes/interactables/echo_orb.tscn") as PackedScene
    var orb := packed.instantiate() as EchoOrb
    orb.position = Vector2(420, 520)
    container.add_child(orb)
    await process_frame
    orb.set_reset_bounds(Rect2(0, 0, 1000, 900))
    orb.set_pedestal(Vector2(640, 440))
    if orb.global_position != Vector2(640, 440):
        failures.append("Orb did not move to its new pedestal")
    orb.global_position = Vector2(1400, 1200)
    orb.active = true
    await physics_frame
    await physics_frame
    if not orb.global_position.is_equal_approx(Vector2(640, 440)):
        failures.append("Out-of-bounds Orb did not recover to pedestal")
    if orb.velocity != Vector2.ZERO or orb.active:
        failures.append("Recovered Orb retained invalid motion")
    container.queue_free()
    await process_frame
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("level2_orb_recovery_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("level2_orb_recovery_test: FAIL (%d)" % failures.size())
    quit(1)
