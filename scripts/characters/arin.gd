class_name ArinController
extends CharacterBody2D

signal knocked_out
signal respawned

const MOVE_SPEED := 260.0
const GROUND_ACCELERATION := 1500.0
const AIR_ACCELERATION := 900.0
const FRICTION := 1700.0
const GRAVITY := 1200.0
const JUMP_VELOCITY := -520.0
const NORMAL_KICK_DAMAGE := 1
const CHARGED_KICK_DAMAGE := 2
const NORMAL_KICK_FORCE := 500.0
const CHARGED_KICK_FORCE := 900.0
const HURT_INVULNERABILITY := 1.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const SWORD_DAMAGE := 2
const SWORD_FORCE := 380.0
const STAR_DAMAGE := 1
const STAR_THROW_COOLDOWN := 0.28
const THROWING_STAR_SCENE: PackedScene = preload(
	"res://scenes/characters/throwing_star.tscn"
)

@onready var visual_root: Node2D = $VisualRoot
@onready var sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var kick_origin: Marker2D = $KickOrigin
@onready var kick_hitbox: Area2D = $KickHitbox
@onready var kick_shape: CollisionShape2D = $KickHitbox/CollisionShape2D
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var sword_pivot: Node2D = $VisualRoot/SwordPivot
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var star_origin: Marker2D = $StarOrigin
@onready var health: HealthComponent = $Components/HealthComponent
@onready var camera: Camera2D = $Camera2D

var facing := 1
var input_locked := false
var attacking := false
var charging := false
var charge_time := 0.0
var attack_power_scale := 1.0
var hurt_state := false
var knockout_state := false
var victory_state := false
var push_fail_state := false
var invulnerable := false
var coyote_left := 0.0
var jump_buffer_left := 0.0
var spawn_position := Vector2.ZERO
var already_hit: Dictionary = {}
var attack_charged := false
var was_on_floor := false
var attack_generation := 0
var damage_generation := 0
var push_generation := 0
var star_throw_cooldown := 0.0
var empty_star_feedback_cooldown := 0.0

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	sprite.sprite_frames = AssetRegistry.build_sprite_frames(
		"arin", Color("3185d8"), Vector2(72, 112)
	)
	sprite.play("idle")
	AssetRegistry.fit_animated_sprite(sprite, Vector2(72, 112))
	health.setup(5)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	kick_hitbox.body_entered.connect(_kick_body_entered)
	kick_hitbox.area_entered.connect(_kick_area_entered)
	sword_hitbox.body_entered.connect(_sword_body_entered)
	kick_shape.disabled = true
	sword_shape.disabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	if not EventBus.cutscene_started.is_connected(lock_input):
		EventBus.cutscene_started.connect(lock_input)
	if not EventBus.cutscene_ended.is_connected(unlock_input):
		EventBus.cutscene_ended.connect(unlock_input)
	if not EventBus.dialogue_active_changed.is_connected(_on_dialogue_active_changed):
		EventBus.dialogue_active_changed.connect(_on_dialogue_active_changed)
	if GameState.dialogue_active:
		_on_dialogue_active_changed(true)

func _exit_tree() -> void:
	attack_generation += 1
	damage_generation += 1
	push_generation += 1
	if EventBus.cutscene_started.is_connected(lock_input):
		EventBus.cutscene_started.disconnect(lock_input)
	if EventBus.cutscene_ended.is_connected(unlock_input):
		EventBus.cutscene_ended.disconnect(unlock_input)
	if EventBus.dialogue_active_changed.is_connected(_on_dialogue_active_changed):
		EventBus.dialogue_active_changed.disconnect(_on_dialogue_active_changed)

func _physics_process(delta: float) -> void:
	if knockout_state:
		return
	star_throw_cooldown = maxf(star_throw_cooldown - delta, 0.0)
	empty_star_feedback_cooldown = maxf(empty_star_feedback_cooldown - delta, 0.0)
	if is_on_floor():
		coyote_left = COYOTE_TIME
	else:
		coyote_left = maxf(coyote_left - delta, 0.0)
		velocity.y += GRAVITY * delta
	var gameplay_input_blocked := _gameplay_input_blocked()
	if gameplay_input_blocked:
		jump_buffer_left = 0.0
	elif Input.is_action_just_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER
	else:
		jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)
	if (
		jump_buffer_left > 0.0
		and coyote_left > 0.0
		and not gameplay_input_blocked
		and not attacking
		and not hurt_state
	):
		velocity.y = JUMP_VELOCITY
		jump_buffer_left = 0.0
		coyote_left = 0.0
		AudioManager.play_sfx("jump_sfx")
	var axis := (
		0.0
		if gameplay_input_blocked or attacking or hurt_state
		else Input.get_axis("move_left", "move_right")
	)
	if absf(axis) > 0.01:
		facing = 1 if axis > 0.0 else -1
		velocity.x = move_toward(
			velocity.x,
			axis * MOVE_SPEED,
			(GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION)
			* delta,
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			(FRICTION if is_on_floor() else AIR_ACCELERATION * 0.35) * delta,
		)
	_apply_facing()
	if charging and gameplay_input_blocked:
		_cancel_attack_state()
	if charging:
		charge_time = minf(charge_time + delta, 1.5)
		EventBus.kick_charge_changed.emit(
			clampf(charge_time / 1.2, 0.0, 1.0)
		)
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > 180.0:
		_landing_feedback()
	was_on_floor = is_on_floor()
	_update_animation()
	AssetRegistry.fit_animated_sprite(sprite, Vector2(72, 112))
	if global_position.y > 1500.0:
		take_damage(99)

func _apply_facing() -> void:
	visual_root.scale.x = absf(visual_root.scale.x) * float(facing)
	kick_origin.position.x = absf(kick_origin.position.x) * float(facing)
	kick_hitbox.position.x = absf(kick_hitbox.position.x) * float(facing)
	sword_hitbox.position.x = absf(sword_hitbox.position.x) * float(facing)
	star_origin.position.x = absf(star_origin.position.x) * float(facing)
	interaction_detector.position.x = (
		absf(interaction_detector.position.x) * float(facing)
	)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_gameplay_input_blocked():
		if _is_gameplay_action_event(event):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		EventBus.restart_requested.emit()
		return
	if input_locked or knockout_state or victory_state or hurt_state:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("sword_attack") and not attacking and not charging:
		_start_sword_attack()
	if event.is_action_pressed("throw_star"):
		_throw_star()
	if event.is_action_pressed("kick") and not attacking and not charging:
		_start_attack(false, 1.0)
	if event.is_action_pressed("charged_kick") and not attacking:
		charging = true
		charge_time = 0.0
		EventBus.kick_charge_changed.emit(0.0)
	if event.is_action_released("charged_kick") and charging:
		var stored_charge := charge_time
		charging = false
		charge_time = 0.0
		EventBus.kick_charge_changed.emit(0.0)
		_start_attack(true, clampf(stored_charge / 1.2, 0.65, 1.15))

func _gameplay_input_blocked() -> bool:
	return input_locked or GameState.is_gameplay_input_blocked()

func _is_gameplay_action_event(event: InputEvent) -> bool:
	for action in [
		"move_left",
		"move_right",
		"jump",
		"kick",
		"charged_kick",
		"sword_attack",
		"throw_star",
		"interact",
		"restart",
	]:
		if event.is_action_pressed(action) or event.is_action_released(action):
			return true
	return false

func _on_dialogue_active_changed(active: bool) -> void:
	if not active:
		return
	jump_buffer_left = 0.0
	_cancel_attack_state()

func _start_attack(charged: bool, power_scale: float) -> void:
	if attacking or knockout_state or hurt_state or _gameplay_input_blocked():
		return
	attack_generation += 1
	var token := attack_generation
	attacking = true
	attack_charged = charged
	attack_power_scale = power_scale
	already_hit.clear()
	velocity.x = 0.0
	sprite.play("charged_kick" if charged else "kick")
	var startup := 0.28 if charged else 0.12
	var active_time := 0.14 if charged else 0.10
	var recovery := 0.30 if charged else 0.16
	await get_tree().create_timer(startup).timeout
	if not _attack_token_valid(token):
		return
	var rectangle := kick_shape.shape as RectangleShape2D
	rectangle.size = Vector2(132, 94) if charged else Vector2(96, 82)
	kick_shape.disabled = false
	AudioManager.play_sfx(
		"charged_kick_sfx" if charged else "kick_sfx"
	)
	EventBus.player_kicked.emit(
		charged,
		kick_origin.global_position,
		Vector2(float(facing), 0),
	)
	_spawn_kick_flash(charged)
	await get_tree().create_timer(active_time).timeout
	if not _attack_token_valid(token):
		return
	kick_shape.disabled = true
	await get_tree().create_timer(recovery).timeout
	if not _attack_token_valid(token):
		return
	attacking = false
	attack_charged = false
	attack_power_scale = 1.0

func _start_sword_attack() -> void:
	if attacking or knockout_state or hurt_state or _gameplay_input_blocked():
		return
	attack_generation += 1
	var token := attack_generation
	attacking = true
	attack_charged = false
	already_hit.clear()
	velocity.x = 0.0
	sprite.play("kick")
	sword_pivot.rotation = -0.95
	var swing := create_tween()
	swing.set_trans(Tween.TRANS_QUAD)
	swing.set_ease(Tween.EASE_OUT)
	swing.tween_property(sword_pivot, "rotation", 1.05, 0.18)
	swing.tween_property(sword_pivot, "rotation", 0.55, 0.14)
	await get_tree().create_timer(0.07).timeout
	if not _attack_token_valid(token):
		return
	sword_shape.disabled = false
	AudioManager.play_sfx("kick_sfx")
	EventBus.player_weapon_used.emit(
		"sword", sword_hitbox.global_position, Vector2(float(facing), 0)
	)
	_spawn_sword_arc()
	await get_tree().create_timer(0.14).timeout
	if not _attack_token_valid(token):
		return
	sword_shape.disabled = true
	await get_tree().create_timer(0.16).timeout
	if not _attack_token_valid(token):
		return
	attacking = false

func _throw_star() -> void:
	if (
		star_throw_cooldown > 0.0
		or attacking
		or charging
		or knockout_state
		or hurt_state
		or _gameplay_input_blocked()
	):
		return
	if not GameState.consume_star():
		if empty_star_feedback_cooldown <= 0.0:
			empty_star_feedback_cooldown = 0.8
			_show_no_stars_feedback()
		return
	star_throw_cooldown = STAR_THROW_COOLDOWN
	var star := THROWING_STAR_SCENE.instantiate() as PlayerThrowingStar
	if star == null:
		return
	get_parent().add_child(star)
	star.global_position = star_origin.global_position
	var throw_direction := Vector2(float(facing), -0.035).normalized()
	star.launch(throw_direction, self, STAR_DAMAGE)
	EventBus.player_weapon_used.emit("star", star.global_position, throw_direction)
	AudioManager.play_sfx("kick_sfx")

func _show_no_stars_feedback() -> void:
	var label := Label.new()
	label.text = "NO STARS"
	label.position = Vector2(-48, -128)
	label.size = Vector2(96, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("ffe36a"))
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -158.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(label.queue_free)

func _sword_body_entered(body: Node) -> void:
	if sword_shape.disabled or body == self:
		return
	var instance_id := body.get_instance_id()
	if already_hit.has(instance_id):
		return
	already_hit[instance_id] = true
	if body.has_method("receive_weapon_hit"):
		body.call(
			"receive_weapon_hit",
			SWORD_DAMAGE,
			Vector2(float(facing), 0),
			"sword",
			self,
		)

func _spawn_sword_arc() -> void:
	var arc := Line2D.new()
	arc.width = 8.0
	arc.default_color = Color(0.68, 0.9, 1.0, 0.9)
	var direction := float(facing)
	for index in 9:
		var angle := lerpf(-0.9, 0.75, float(index) / 8.0)
		arc.add_point(Vector2(cos(angle) * 82.0 * direction, sin(angle) * 64.0 - 48.0))
	add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.16)
	tween.tween_callback(arc.queue_free)

func _attack_token_valid(token: int) -> bool:
	return (
		token == attack_generation
		and is_inside_tree()
		and not knockout_state
		and not hurt_state
	)

func _cancel_attack_state() -> void:
	attack_generation += 1
	attacking = false
	charging = false
	attack_charged = false
	attack_power_scale = 1.0
	charge_time = 0.0
	already_hit.clear()

	if is_instance_valid(kick_shape):
		kick_shape.set_deferred("disabled", true)
	if is_instance_valid(sword_shape):
		sword_shape.set_deferred("disabled", true)
	if is_instance_valid(sword_pivot):
		sword_pivot.rotation = 0.55

	EventBus.kick_charge_changed.emit(0.0)
func _kick_body_entered(body: Node) -> void:
	_apply_kick(body)

func _kick_area_entered(area: Area2D) -> void:
	_apply_kick(area)

func _apply_kick(target: Object) -> void:
	if kick_shape.disabled or target == self:
		return
	var instance_id := target.get_instance_id()
	if already_hit.has(instance_id):
		return
	already_hit[instance_id] = true
	if target.has_method("receive_kick"):
		target.call(
			"receive_kick",
			(
				CHARGED_KICK_FORCE
				if attack_charged
				else NORMAL_KICK_FORCE
			)
			* attack_power_scale,
			CHARGED_KICK_DAMAGE if attack_charged else NORMAL_KICK_DAMAGE,
			Vector2(float(facing), 0),
			attack_charged,
			self,
		)

func _try_interact() -> void:
	var candidates := (
		interaction_detector.get_overlapping_areas()
		+ interaction_detector.get_overlapping_bodies()
	)
	for target: Node in candidates:
		if target.has_method("interact"):
			target.call("interact", self)
			return

func play_push_fail() -> void:
	if attacking or knockout_state or hurt_state:
		return
	push_generation += 1
	var token := push_generation
	push_fail_state = true
	input_locked = true
	sprite.play("push_fail")
	await get_tree().create_timer(0.7).timeout
	if token != push_generation or not is_inside_tree():
		return
	push_fail_state = false
	if not knockout_state and not victory_state and not hurt_state:
		input_locked = false

func play_victory() -> void:
	_cancel_attack_state()
	victory_state = true
	input_locked = true
	velocity = Vector2.ZERO
	sprite.play("victory")

func lock_input() -> void:
	input_locked = true

func unlock_input() -> void:
	if not victory_state and not knockout_state and not hurt_state:
		input_locked = false


func set_cinematic_control(active: bool) -> void:
	if active:
		_cancel_attack_state()
		velocity = Vector2.ZERO
		lock_input()
		set_physics_process(false)
	else:
		set_physics_process(true)
		unlock_input()
		velocity = Vector2.ZERO
		_update_animation()

func set_cinematic_facing(direction: int) -> void:
	facing = 1 if direction >= 0 else -1
	_apply_facing()

func play_cinematic_animation(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func take_damage(
	amount: int, knockback_force: Vector2 = Vector2.ZERO
) -> void:
	if invulnerable or knockout_state:
		return
	_cancel_attack_state()
	velocity += knockback_force
	health.damage(amount)

func _on_damaged(amount: int) -> void:
	damage_generation += 1
	var token := damage_generation
	invulnerable = true
	hurt_state = true
	input_locked = true
	GameState.current_health = health.current_health
	GameState.damage_taken += amount
	EventBus.player_damaged.emit(amount)
	EventBus.player_health_changed.emit(
		health.current_health, health.max_health
	)
	AudioManager.play_sfx("hurt_sfx")
	sprite.play("hurt")
	modulate = Color("ff8a80")
	_camera_shake(8.0)
	await get_tree().create_timer(0.22).timeout
	if token != damage_generation or not is_inside_tree() or knockout_state:
		return
	hurt_state = false
	if not victory_state:
		input_locked = false
	await get_tree().create_timer(HURT_INVULNERABILITY - 0.22).timeout
	if token != damage_generation or not is_inside_tree() or knockout_state:
		return
	modulate = Color.WHITE
	invulnerable = false

func _on_died() -> void:
	damage_generation += 1
	_cancel_attack_state()
	knockout_state = true
	hurt_state = false
	input_locked = true
	velocity = Vector2.ZERO
	sprite.play("knockout")
	GameState.game_state = GameState.GameMode.FAILED
	EventBus.player_died.emit()
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree():
		knocked_out.emit()

func reset_to_spawn(position_override: Vector2 = Vector2.INF) -> void:
	attack_generation += 1
	damage_generation += 1
	push_generation += 1
	global_position = (
		spawn_position if position_override == Vector2.INF else position_override
	)
	velocity = Vector2.ZERO
	health.reset()
	GameState.current_health = health.current_health
	EventBus.player_health_changed.emit(
		health.current_health, health.max_health
	)
	knockout_state = false
	hurt_state = false
	victory_state = false
	push_fail_state = false
	attacking = false
	charging = false
	attack_charged = false
	charge_time = 0.0
	attack_power_scale = 1.0
	input_locked = false
	invulnerable = false
	modulate = Color.WHITE
	kick_shape.disabled = true
	sword_shape.disabled = true
	sword_pivot.rotation = 0.55
	star_throw_cooldown = 0.0
	EventBus.kick_charge_changed.emit(0.0)
	sprite.play("idle")
	respawned.emit()

func set_spawn(value: Vector2) -> void:
	spawn_position = value

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom

func _landing_feedback() -> void:
	_camera_shake(2.0)
	var texture := AssetRegistry.load_texture("dust")
	var dust: CanvasItem
	if texture != null:
		var dust_sprite := Sprite2D.new()
		dust_sprite.texture = texture
		dust = dust_sprite
	else:
		var cloud := Polygon2D.new()
		cloud.polygon = PackedVector2Array([
			Vector2(-35, 0),
			Vector2(-18, -13),
			Vector2(0, -5),
			Vector2(18, -13),
			Vector2(35, 0),
		])
		cloud.color = Color(0.75, 0.78, 0.82, 0.55)
		dust = cloud
	add_child(dust)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dust, "modulate:a", 0.0, 0.25)
	tween.tween_property(dust, "scale", Vector2(1.35, 0.75), 0.25)
	tween.chain().tween_callback(dust.queue_free)

func _camera_shake(strength: float) -> void:
	var original := camera.offset
	camera.offset = Vector2(
		randf_range(-strength, strength), randf_range(-strength, strength)
	)
	var tween := create_tween()
	tween.tween_property(camera, "offset", original, 0.16)

func _spawn_kick_flash(charged: bool) -> void:
	var texture := AssetRegistry.load_texture(
		"charged_kick_flash" if charged else "kick_flash"
	)
	var flash: CanvasItem
	if texture != null:
		var flash_sprite := Sprite2D.new()
		flash_sprite.texture = texture
		flash_sprite.position = Vector2(float(facing) * 72.0, -45)
		flash_sprite.flip_h = facing < 0
		flash = flash_sprite
	else:
		var flash_polygon := Polygon2D.new()
		var length := 125.0 if charged else 85.0
		flash_polygon.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(float(facing) * length, -24),
			Vector2(float(facing) * length, 24),
		])
		flash_polygon.color = Color("ffd54f") if charged else Color("fff59d")
		flash_polygon.position = Vector2(float(facing) * 30, -45)
		flash = flash_polygon
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)

func _update_animation() -> void:
	if (
		knockout_state
		or hurt_state
		or attacking
		or push_fail_state
		or victory_state
	):
		return
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 25.0:
		sprite.play("run")
	else:
		sprite.play("idle")
