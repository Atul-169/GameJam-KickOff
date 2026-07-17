class_name Football
extends RigidBody2D

signal kicked(charged: bool)

@export var reset_below_y := 1300.0

var spawn_position := Vector2.ZERO
var cinematic_controlled := false
var _gameplay_collision_layer := CollisionLayers.KICKABLE
var _gameplay_collision_mask := (
    CollisionLayers.WORLD | CollisionLayers.PLAYER | CollisionLayers.TRIGGER
)

func _ready() -> void:
    collision_layer = _gameplay_collision_layer
    collision_mask = _gameplay_collision_mask
    gravity_scale = 1.25
    mass = 0.55
    linear_damp = 0.55
    angular_damp = 0.35
    continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
    spawn_position = global_position
    var visual := AssetRegistry.make_visual(
        "football", Vector2(46, 46), Color("f5f5f5"), ""
    )
    add_child(visual)
    add_to_group("resettable")

func _physics_process(_delta: float) -> void:
    if not cinematic_controlled and global_position.y > reset_below_y:
        reset_ball()

func set_cinematic_control(active: bool) -> void:
    cinematic_controlled = active
    freeze = active
    sleeping = active
    linear_velocity = Vector2.ZERO
    angular_velocity = 0.0
    collision_layer = 0 if active else _gameplay_collision_layer
    collision_mask = 0 if active else _gameplay_collision_mask
    contact_monitor = not active

func receive_kick(
    force: float,
    _damage: int,
    direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if cinematic_controlled:
        return
    sleeping = false
    apply_central_impulse(
        (direction + Vector2(0, -0.18)).normalized() * force * 0.72
    )
    apply_torque_impulse(force * 0.08 * direction.x)
    kicked.emit(charged)

func reset_ball() -> void:
    freeze = true
    global_position = spawn_position
    linear_velocity = Vector2.ZERO
    angular_velocity = 0.0
    if not cinematic_controlled:
        freeze = false

func reset_state() -> void:
    reset_ball()
