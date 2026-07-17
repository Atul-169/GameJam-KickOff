extends CharacterBody2D

@export var move_speed: float = 240.0
@export var gravity: float = 1250.0
@export var jump_velocity: float = -500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var action_locked: bool = false


func _ready() -> void:
    play_animation("idle")


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    if not action_locked:
        handle_movement()
        handle_jump()
        handle_actions()

    move_and_slide()
    update_animation()


func handle_movement() -> void:
    var direction := Input.get_axis("move_left", "move_right")
    velocity.x = direction * move_speed

    if direction != 0.0:
        sprite.flip_h = direction < 0.0
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed)


func handle_jump() -> void:
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
        play_animation("jump")


func handle_actions() -> void:
    if Input.is_action_just_pressed("charged_kick"):
        play_locked_action("charged_kick")
    elif Input.is_action_just_pressed("push_fail"):
        play_locked_action("push_fail")
    elif Input.is_action_just_pressed("kick"):
        play_locked_action("kick")


func update_animation() -> void:
    if action_locked:
        return

    if not is_on_floor():
        if velocity.y < 0.0:
            play_animation("jump")
        else:
            play_animation("fall")
    elif abs(velocity.x) > 5.0:
        play_animation("run")
    else:
        play_animation("idle")


func play_animation(animation_name: StringName) -> void:
    if sprite.animation != animation_name:
        sprite.play(animation_name)


func play_locked_action(animation_name: StringName) -> void:
    action_locked = true
    velocity.x = 0.0
    sprite.play(animation_name)
    await sprite.animation_finished
    action_locked = false
