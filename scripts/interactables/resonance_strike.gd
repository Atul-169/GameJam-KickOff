class_name ResonanceStrike
extends Area2D


@export var lifetime: float = 0.20

var charged: bool = true
var consumed: bool = false
var generation: int = 0


func _ready() -> void:
	collision_layer = CollisionLayers.PLAYER_KICK
	collision_mask = (
		CollisionLayers.ENEMY
		| CollisionLayers.TRIGGER
	)

	monitoring = true
	monitorable = true

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	add_to_group("temporary")
	_build_visual()

	generation += 1
	var token: int = generation

	await get_tree().create_timer(lifetime).timeout

	if token == generation and is_inside_tree():
		queue_free()


func configure(is_charged: bool) -> void:
	charged = is_charged


func is_resonance_strike() -> bool:
	return charged and not consumed


func consume() -> void:
	if consumed:
		return

	consumed = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _on_area_entered(area: Area2D) -> void:
	if consumed:
		return

	if area.has_method("receive_resonance_strike"):
		area.call(
			"receive_resonance_strike",
			self
		)


func _on_body_entered(body: Node) -> void:
	if consumed:
		return

	if body.has_method("receive_resonance_strike"):
		body.call(
			"receive_resonance_strike",
			self
		)


func _build_visual() -> void:
	var visual: Node2D = AssetRegistry.make_visual(
		"resonance_strike",
		Vector2(124.0, 124.0),
		Color("8defff"),
		""
	)

	add_child(visual)

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(1.45, 1.45),
		lifetime
	)

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		lifetime
	)
