class_name AncientSeal
extends Area2D

signal hand_attempted
signal kicked_open

var enabled := true
var interaction_enabled := true
var kick_enabled := false
var hand_used := false
var opened := false
var kick_receiver: SealKickReceiver
var _initial_enabled := true
var _initial_interaction_enabled := true
var _initial_kick_enabled := false

func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 96.0
	shape_node.shape = circle
	add_child(shape_node)

	kick_receiver = SealKickReceiver.new()
	kick_receiver.configure(self)
	var kick_shape_node := CollisionShape2D.new()
	var kick_circle := CircleShape2D.new()
	kick_circle.radius = 96.0
	kick_shape_node.shape = kick_circle
	kick_receiver.add_child(kick_shape_node)
	add_child(kick_receiver)





	_initial_enabled = enabled
	_initial_interaction_enabled = interaction_enabled
	_initial_kick_enabled = kick_enabled
	_apply_collision_state()
	add_to_group("resettable")

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		interaction_enabled = false
		kick_enabled = false
	_apply_collision_state()

func set_interaction_enabled(value: bool) -> void:
	interaction_enabled = value and enabled and not opened
	_apply_collision_state()

func set_kick_enabled(value: bool) -> void:
	kick_enabled = value and enabled and not opened
	_apply_collision_state()


func set_hand_attempted(value: bool) -> void:
	hand_used = value
	if value:
		interaction_enabled = false
	_apply_collision_state()

func can_interact() -> bool:
	return enabled and interaction_enabled and not opened

func can_receive_kick() -> bool:
	return enabled and kick_enabled and hand_used and not opened

func disable_detection_keep_visible() -> void:
	interaction_enabled = false
	kick_enabled = false

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if kick_receiver != null:
		kick_receiver.set_detection_enabled(false)

func _apply_collision_state() -> void:
	visible = enabled

	var interaction_active := (
		enabled
		and interaction_enabled
		and not opened
	)

	# These properties must not change directly during an Area2D signal.
	set_deferred("monitoring", false)
	set_deferred("monitorable", interaction_active)
	set_deferred(
		"collision_layer",
		CollisionLayers.TRIGGER if interaction_active else 0
	)
	set_deferred("collision_mask", 0)

	if kick_receiver != null:
		kick_receiver.set_detection_enabled(
			enabled
			and kick_enabled
			and hand_used
			and not opened
		)
func interact(source: Node) -> void:
	if not can_interact():
		return
	interaction_enabled = false
	hand_used = true
	_apply_collision_state()
	if source.has_method("play_push_fail"):
		source.call("play_push_fail")
	hand_attempted.emit()

func attempt_kick(
	_force: float,
	_damage: int,
	_direction: Vector2,
	_charged: bool,
	_source: Node
) -> void:
	if not can_receive_kick():
		return

	opened = true
	kick_enabled = false
	interaction_enabled = false
	modulate = Color("ffe37c")

	_apply_collision_state()
	call_deferred("_emit_kicked_open")


func _emit_kicked_open() -> void:
	kicked_open.emit()
	
func reset_state() -> void:
	hand_used = false
	opened = false
	modulate = Color.WHITE
	enabled = _initial_enabled
	interaction_enabled = _initial_interaction_enabled
	kick_enabled = _initial_kick_enabled
	_apply_collision_state()
