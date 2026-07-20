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

	var visual := AssetRegistry.make_visual(
		"rotating_gear",
		Vector2(radius * 2.0, radius * 2.0),
		Color("8c96a5"),
		""
	)
	add_child(visual)

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
