class_name RotatingGear
extends Area2D

@export var radius := 92.0
@export var speed := 1.4

var active := false
var cooldown: Dictionary = {}

func _ready() -> void:
    collision_layer = CollisionLayers.HAZARD
    collision_mask = CollisionLayers.PLAYER
    monitoring = true
    body_entered.connect(_hit)
    add_to_group("freezable")
    add_to_group("resettable")

    var line := Line2D.new()
    line.width = 18.0
    line.default_color = Color("8c96a5")
    var points := PackedVector2Array()
    for i in 25:
        var point_radius := radius + (12.0 if i % 3 == 0 else 0.0)
        points.append(
            Vector2.from_angle(float(i) / 24.0 * TAU) * point_radius
        )
    line.points = points
    add_child(line)

func _process(delta: float) -> void:
    if active:
        rotation += speed * delta

func _hit(body: Node) -> void:
    if not active or not body.has_method("take_damage"):
        return
    var instance_id := body.get_instance_id()
    if cooldown.has(instance_id):
        return
    cooldown[instance_id] = true
    var force := global_position.direction_to(body.global_position) * 260.0
    body.call("take_damage", 1, force)
    await get_tree().create_timer(0.8).timeout
    cooldown.erase(instance_id)

func set_world_active(value: bool) -> void:
    active = value

func reset_state() -> void:
    active = false
    rotation = 0.0
    cooldown.clear()
