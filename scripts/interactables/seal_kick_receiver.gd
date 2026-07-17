class_name SealKickReceiver
extends Area2D

var seal: AncientSeal
var detection_enabled := false

func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0

func configure(value: AncientSeal) -> void:
	seal = value

func set_detection_enabled(value: bool) -> void:
	detection_enabled = value

	set_deferred("monitoring", false)
	set_deferred("monitorable", value)
	set_deferred(
		"collision_layer",
		CollisionLayers.TRIGGER if value else 0
	)
	set_deferred("collision_mask", 0)

func receive_kick(
	force: float,
	damage: int,
	direction: Vector2,
	charged: bool,
	source: Node
) -> void:
	if not detection_enabled or seal == null or not is_instance_valid(seal):
		return
	seal.attempt_kick(force, damage, direction, charged, source)
