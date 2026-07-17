class_name NikoCharacter
extends CharacterBody2D

signal destination_reached

@onready var sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D

var target_position := Vector2.ZERO
var scripted_move := false
var move_speed := 230.0
var cinematic_controlled := false

func _ready() -> void:
    sprite.sprite_frames = AssetRegistry.build_sprite_frames(
        "niko", Color("22a884"), Vector2(68, 108)
    )
    sprite.play("idle")
    AssetRegistry.fit_animated_sprite(sprite, Vector2(68, 108))

func _physics_process(delta: float) -> void:
    if cinematic_controlled:
        return
    if scripted_move:
        var dx := target_position.x - global_position.x
        velocity.x = clampf(dx * 3.0, -move_speed, move_speed)
        if absf(dx) < 5.0:
            velocity.x = 0.0
            scripted_move = false
            destination_reached.emit()
        sprite.flip_h = velocity.x < 0.0
        sprite.play("run" if absf(velocity.x) > 5.0 else "idle")
    if not is_on_floor():
        velocity.y += 1200.0 * delta
    move_and_slide()
    AssetRegistry.fit_animated_sprite(sprite, Vector2(68, 108))

func set_cinematic_control(active: bool) -> void:
    cinematic_controlled = active
    scripted_move = false
    velocity = Vector2.ZERO
    set_physics_process(not active)

func set_cinematic_facing(direction: int) -> void:
    sprite.flip_h = direction < 0

func move_to(point: Vector2) -> void:
    target_position = point
    scripted_move = true

func move_to_and_wait(point: Vector2) -> void:
    move_to(point)
    while scripted_move and is_inside_tree():
        await get_tree().physics_frame

func play_state(state: String) -> void:
    if sprite.sprite_frames.has_animation(state):
        sprite.play(state)
    elif sprite.sprite_frames.has_animation("idle"):
        sprite.play("idle")

func fall_through(distance: float = 420.0) -> void:
    scripted_move = false
    velocity = Vector2.ZERO
    set_physics_process(false)
    play_state("fall")
    var tween := create_tween()
    tween.tween_property(
        self, "position:y", position.y + distance, 1.0
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    await tween.finished
    visible = false

func rescue() -> void:
    visible = true
    cinematic_controlled = false
    set_physics_process(true)
    play_state("rescue")
