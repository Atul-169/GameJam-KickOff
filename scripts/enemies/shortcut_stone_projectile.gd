class_name ShortcutStoneProjectile
extends Area2D

@export var speed := 460.0
@export var life_time := 4.0

var direction := Vector2.LEFT
var source: Node
var spent := false


func _ready() -> void:
	collision_layer = CollisionLayers.ENEMY_ATTACK
	collision_mask = CollisionLayers.WORLD | CollisionLayers.PLAYER
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	add_to_group("temporary")
	z_index = 18
	add_child(AssetRegistry.make_visual("falling_rock", Vector2(42, 42), Color("75685d"), ""))


func launch(direction_value: Vector2, source_value: Node) -> void:
	direction = direction_value.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	source = source_value


func _physics_process(delta: float) -> void:
	if spent:
		return
	global_position += direction * speed * delta
	rotation += 7.5 * delta * signf(direction.x)
	life_time -= delta
	if life_time <= 0.0:
		shatter()


func _on_body_entered(body: Node) -> void:
	if spent or body == source:
		return
	if body is ArinController:
		(body as ArinController).take_damage(1, direction * 190.0 + Vector2(0, -55))
	shatter()


func shatter() -> void:
	if spent:
		return
	spent = true
	set_deferred("monitoring", false)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", true)
	visible = false
	_spawn_debris()
	await get_tree().create_timer(0.04).timeout
	if is_inside_tree():
		queue_free()


func _spawn_debris() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	for index in 4:
		var chip := Polygon2D.new()
		chip.polygon = PackedVector2Array([Vector2(-5, -4), Vector2(6, -2), Vector2(2, 6)])
		chip.color = Color("89786b")
		chip.z_index = 19
		parent_node.add_child(chip)
		chip.global_position = global_position
		var offset := Vector2(float(index - 2) * 17.0, -26.0 - float(index % 2) * 12.0)
		var tween := chip.create_tween()
		tween.set_parallel(true)
		tween.tween_property(chip, "position", chip.position + offset, 0.22)
		tween.tween_property(chip, "modulate:a", 0.0, 0.22)
		tween.chain().tween_callback(chip.queue_free)
