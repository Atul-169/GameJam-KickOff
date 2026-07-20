class_name ReflectableProjectile
extends Area2D


var velocity := Vector2.ZERO

var active := false
var reflected := false
var reflectable := false
var reflectable_on_activation := false

var life := 7.0
var owner_enemy: Node

var visual: Polygon2D
var activation_generation := 0

var collision_consumed := false


func _ready() -> void:
	body_entered.connect(_body_entered)
	area_entered.connect(_area_entered)

	visual = Polygon2D.new()

	visual.polygon = PackedVector2Array(
		[
			Vector2(-18, -12),
			Vector2(20, 0),
			Vector2(-18, 12)
		]
	)

	visual.color = Color("ef5350")
	add_child(visual)

	var trail_texture := AssetRegistry.load_texture(
		"projectile_trail"
	)

	if trail_texture != null:
		var trail_sprite := Sprite2D.new()

		trail_sprite.texture = trail_texture
		trail_sprite.position = Vector2(-24, 0)
		trail_sprite.z_index = -1

		add_child(trail_sprite)

	add_to_group("freezable")
	add_to_group("temporary")

	_set_collision_enabled(false)


func launch(
	value: Vector2,
	source: Node
) -> void:
	activation_generation += 1
	var token := activation_generation

	velocity = value
	owner_enemy = source

	active = true
	reflected = false
	reflectable = false
	reflectable_on_activation = false
	collision_consumed = false

	life = 7.0

	_set_collision_enabled(true)

	visual.color = Color("ff6b6b")
	visual.modulate = Color.WHITE
	visual.scale = Vector2.ONE

	await get_tree().create_timer(
		0.45
	).timeout

	if (
		token != activation_generation
		or not active
		or collision_consumed
		or not is_inside_tree()
	):
		return

	reflectable = true
	visual.color = Color("ffe082")

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(
		visual,
		"scale",
		Vector2(1.25, 1.25),
		0.12
	)

	tween.tween_property(
		visual,
		"scale",
		Vector2.ONE,
		0.12
	)


func configure_suspended(
	value: Vector2,
	can_reflect: bool = true
) -> void:
	activation_generation += 1

	velocity = value
	reflectable_on_activation = can_reflect

	reflected = false
	reflectable = false
	collision_consumed = false

	life = 20.0

	set_world_active(false)


func set_world_active(
	value: bool
) -> void:
	activation_generation += 1

	active = value

	if active:
		collision_consumed = false
		life = maxf(life, 7.0)

		_set_collision_enabled(true)

		reflectable = reflectable_on_activation

		if reflectable:
			visual.color = Color("ffe082")
		else:
			visual.color = Color("ff6b6b")

	else:
		if reflectable:
			reflectable_on_activation = true

		reflectable = false

		_set_collision_enabled(false)


func _set_collision_enabled(
	value: bool
) -> void:
	monitoring = value
	monitorable = value

	if value:
		collision_layer = CollisionLayers.PROJECTILE

		collision_mask = (
			CollisionLayers.WORLD
			| CollisionLayers.PLAYER
			| CollisionLayers.ENEMY
			| CollisionLayers.TRIGGER
		)
	else:
		collision_layer = 0
		collision_mask = 0


func _physics_process(
	delta: float
) -> void:
	if not active or collision_consumed:
		return

	position += velocity * delta
	life -= delta
	rotation = velocity.angle()

	if life <= 0.0:
		_consume_projectile()


func receive_kick(
	force: float,
	_damage: int,
	direction: Vector2,
	_charged: bool,
	source: Node
) -> void:
	if (
		not active
		or collision_consumed
		or not reflectable
		or reflected
	):
		return

	reflected = true
	reflectable = false

	visual.color = Color("65e7ff")

	collision_mask = (
		CollisionLayers.WORLD
		| CollisionLayers.ENEMY
		| CollisionLayers.TRIGGER
	)

	var target_point := (
		global_position
		+ direction.normalized() * 600.0
	)

	var level := get_tree().get_first_node_in_group(
		"level_manager"
	)

	if (
		level != null
		and level.has_method(
			"get_reflect_target_from"
		)
	):
		target_point = level.call(
			"get_reflect_target_from",
			global_position
		)

	elif (
		level != null
		and level.has_method(
			"get_reflect_target"
		)
	):
		target_point = level.call(
			"get_reflect_target"
		)

	var target_direction := global_position.direction_to(
		target_point
	)

	if target_direction == Vector2.ZERO:
		target_direction = direction.normalized()

	if target_direction == Vector2.ZERO:
		target_direction = Vector2.RIGHT

	velocity = (
		target_direction
		* maxf(force * 0.72, 520.0)
	)

	owner_enemy = source

	AudioManager.play_sfx(
		"projectile_reflect_sfx"
	)


func is_reflected() -> bool:
	return reflected


func _body_entered(
	body: Node
) -> void:
	if (
		not active
		or collision_consumed
		or body == owner_enemy
	):
		return

	if body is ArinController and not reflected:
		body.take_damage(
			1,
			velocity.normalized() * 220.0
		)

		_consume_projectile()
		return

	if reflected and body is EnemyBase:
		_consume_projectile()

		if is_instance_valid(body):
			body.receive_projectile(
				true,
				self
			)

		return

	if (
		reflected
		and body.has_method(
			"receive_projectile"
		)
	):
		_consume_projectile()

		if is_instance_valid(body):
			body.call(
				"receive_projectile",
				true,
				self
			)

		return

	if body is StaticBody2D:
		print(
			"Reflected projectile blocked by: ",
			body.get_path(),
			" at ",
			global_position
		)

		_consume_projectile()


func _area_entered(
	area: Area2D
) -> void:
	if (
		not active
		or collision_consumed
		or not reflected
	):
		return

	if not area.has_method(
		"receive_projectile"
	):
		return

	_consume_projectile()

	if is_instance_valid(area):
		area.call(
			"receive_projectile",
			true,
			self
		)


func _consume_projectile() -> void:
	if collision_consumed:
		return

	collision_consumed = true
	active = false
	reflectable = false

	activation_generation += 1

	_set_collision_enabled(false)

	queue_free()
