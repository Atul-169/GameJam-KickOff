class_name ShortcutLift
extends AnimatableBody2D

signal arrived

@export var rise_offset := Vector2(0, -520)
@export var duration := 2.6

var start_position := Vector2.ZERO
var activated := false
var moving := false
var at_top := false

var boarding_area: Area2D
var move_tween: Tween


func _ready() -> void:
    collision_layer = CollisionLayers.WORLD
    collision_mask = CollisionLayers.PLAYER
    start_position = position
    add_to_group("resettable")

    var visual := AssetRegistry.make_visual(
        "shortcut_lift",
        Vector2(220, 44),
        Color("4d8f87"),
        "LIFT"
    )
    add_child(visual)

    # This area verifies that Arin is standing on the platform before
    # Switch B is allowed to start the lift.
    boarding_area = Area2D.new()
    boarding_area.name = "BoardingArea"
    boarding_area.position = Vector2(0, -58)
    boarding_area.collision_layer = 0
    boarding_area.collision_mask = CollisionLayers.PLAYER
    boarding_area.monitoring = true
    boarding_area.monitorable = false
    add_child(boarding_area)

    var boarding_shape := CollisionShape2D.new()
    boarding_shape.name = "CollisionShape2D"

    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(190, 92)
    boarding_shape.shape = rectangle

    boarding_area.add_child(boarding_shape)


func is_player_on_lift(player: Node) -> bool:
    if (
        player == null
        or not is_instance_valid(player)
        or boarding_area == null
        or not is_instance_valid(boarding_area)
    ):
        return false

    return player in boarding_area.get_overlapping_bodies()


func activate() -> void:
    if activated or moving or at_top:
        return

    activated = true
    call_deferred("_start_rise")


func _start_rise() -> void:
    if moving or at_top or not is_inside_tree():
        return

    moving = true

    # Small delay gives Arin time to finish the kick/hurt reaction while
    # remaining on the platform.
    await get_tree().create_timer(0.20).timeout

    if not is_inside_tree():
        return

    move_tween = create_tween()
    move_tween.tween_property(
        self,
        "position",
        start_position + rise_offset,
        duration
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    await move_tween.finished

    if not is_inside_tree():
        return

    moving = false
    at_top = true
    arrived.emit()


func reset_state() -> void:
    if move_tween != null and move_tween.is_valid():
        move_tween.kill()

    move_tween = null
    activated = false
    moving = false
    at_top = false
    position = start_position
