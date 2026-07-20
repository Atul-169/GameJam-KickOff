class_name ShortcutStoneThrower
extends EnemyBase

const STONE_SCENE: PackedScene = preload("res://scenes/enemies/shortcut_stone_projectile.tscn")

@export var throw_interval := 2.2
@export var first_throw_delay := 0.85
@export var detection_range := 1150.0
@export var shortcut_min_y := 1080.0
@export var visual_scale := 2.4

var throw_timer := 0.0
var facing := -1
var active_stone: ShortcutStoneProjectile
var kick_hint_cooldown := 0.0


func _ready() -> void:
	super._ready()
	throw_timer = first_throw_delay
	visual_root.position = Vector2(0, -110)
	visual_root.scale = Vector2(visual_scale, visual_scale)
	if health_bar != null:
		health_bar.position = Vector2(0, -245)


func think(delta: float) -> void:
	velocity.x = 0.0
	kick_hint_cooldown = maxf(kick_hint_cooldown - delta, 0.0)
	if not _player_is_in_shortcut():
		throw_timer = minf(throw_timer, first_throw_delay)
		return
	facing = 1 if target.global_position.x > global_position.x else -1
	visual_root.scale.x = absf(visual_root.scale.x) * float(facing)
	if active_stone != null and is_instance_valid(active_stone):
		return
	throw_timer -= delta
	if throw_timer <= 0.0:
		_throw_stone()
		throw_timer = throw_interval


func _player_is_in_shortcut() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return (
		target.global_position.y >= shortcut_min_y
		and absf(target.global_position.x - global_position.x) <= detection_range
	)


func _throw_stone() -> void:
	active_stone = STONE_SCENE.instantiate() as ShortcutStoneProjectile
	if active_stone == null:
		return
	get_parent().add_child(active_stone)
	active_stone.global_position = global_position + Vector2(float(facing) * 58.0, -30.0)
	active_stone.launch(Vector2(float(facing), 0.0), self)
	AudioManager.play_sfx("rock_fall_sfx")
	var original_rotation := visual_root.rotation
	var throw_tween := create_tween()
	throw_tween.tween_property(visual_root, "rotation", -0.10 * float(facing), 0.08)
	throw_tween.tween_property(visual_root, "rotation", original_rotation, 0.12)


func receive_weapon_hit(
	_damage: int, _direction: Vector2, _weapon: String, _source: Node = null
) -> void:
	if not can_receive_combat_effects():
		return
	_hit_feedback(false)
	if kick_hint_cooldown <= 0.0:
		kick_hint_cooldown = 0.8
		_show_kick_only_hint()


func receive_kick(
	force: float, damage: int, direction: Vector2, charged: bool, source: Node
) -> void:
	super.receive_kick(force, maxi(damage, 1), direction, charged, source)
	if dead and active_stone != null and is_instance_valid(active_stone):
		active_stone.shatter()


func _show_kick_only_hint() -> void:
	var hint := Label.new()
	hint.text = "KICK ONLY"
	hint.position = Vector2(-70, -285)
	hint.size = Vector2(140, 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("ffd86b"))
	add_child(hint)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hint, "position:y", -315.0, 0.55)
	tween.tween_property(hint, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(hint.queue_free)


func reset_state() -> void:
	if active_stone != null and is_instance_valid(active_stone):
		active_stone.shatter()
	active_stone = null
	throw_timer = first_throw_delay
	kick_hint_cooldown = 0.0
	super.reset_state()
