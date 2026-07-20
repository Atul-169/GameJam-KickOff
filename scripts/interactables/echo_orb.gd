class_name EchoOrb
extends CharacterBody2D

signal kicked_off

@export var prompt_distance := 260.0

var spawn_position := Vector2.ZERO
var reset_bounds := Rect2(-200, -200, 5000, 1500)
var orb_enabled := true
var pressed := false

var orb_visual: Node2D
var button_prompt: Node2D
var prompt_background: Polygon2D
var prompt_border: Line2D
var prompt_label: Label


func _ready() -> void:
    collision_layer = CollisionLayers.KICKABLE
    collision_mask = CollisionLayers.WORLD | CollisionLayers.TRIGGER
    spawn_position = global_position

    orb_visual = AssetRegistry.make_visual(
        "echo_orb",
        Vector2(48, 48),
        Color("70d6ff"),
        ""
    )
    add_child(orb_visual)

    _build_button_prompt()
    _update_button_prompt()

    add_to_group("resettable")
    add_to_group("echo_orb")


func _physics_process(_delta: float) -> void:
    _update_button_prompt()


func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    _charged: bool,
    _source: Node
) -> void:
    if not orb_enabled or pressed:
        return

    pressed = true
    AudioManager.play_sfx("rune_sfx")
    _play_press_feedback()
    _update_button_prompt()
    kicked_off.emit()


func shadow_kick(_direction: Vector2, charged: bool) -> void:
    receive_kick(760.0 if charged else 470.0, 0, Vector2.ZERO, charged, self)


func set_pedestal(position_value: Vector2) -> void:
    spawn_position = position_value
    global_position = spawn_position
    _update_button_prompt()


func set_reset_bounds(bounds: Rect2) -> void:
    # Kept for compatibility with the level script. This fixed button no
    # longer moves, so the bounds are not otherwise needed.
    reset_bounds = bounds


func set_orb_enabled(enabled: bool) -> void:
    orb_enabled = enabled

    if enabled:
        collision_layer = CollisionLayers.KICKABLE
        collision_mask = CollisionLayers.WORLD | CollisionLayers.TRIGGER
    else:
        collision_layer = 0
        collision_mask = 0

    _update_button_prompt()


func reset_orb() -> void:
    global_position = spawn_position
    pressed = false
    modulate = Color.WHITE

    if orb_visual != null and is_instance_valid(orb_visual):
        orb_visual.scale = Vector2.ONE

    _update_button_prompt()


func reset_state() -> void:
    set_orb_enabled(true)
    reset_orb()


func _get_player() -> Node2D:
    return get_tree().get_first_node_in_group("player") as Node2D


func _build_button_prompt() -> void:
    button_prompt = Node2D.new()
    button_prompt.name = "KickButtonPrompt"
    button_prompt.position = Vector2(0.0, -82.0)
    button_prompt.z_index = 20
    add_child(button_prompt)

    prompt_background = Polygon2D.new()
    prompt_background.polygon = PackedVector2Array([
        Vector2(-78.0, -21.0),
        Vector2(78.0, -21.0),
        Vector2(78.0, 21.0),
        Vector2(-78.0, 21.0),
    ])
    prompt_background.color = Color(0.035, 0.075, 0.12, 0.94)
    button_prompt.add_child(prompt_background)

    prompt_border = Line2D.new()
    prompt_border.width = 2.0
    prompt_border.default_color = Color("65dfff")
    prompt_border.points = PackedVector2Array([
        Vector2(-78.0, -21.0),
        Vector2(78.0, -21.0),
        Vector2(78.0, 21.0),
        Vector2(-78.0, 21.0),
        Vector2(-78.0, -21.0),
    ])
    button_prompt.add_child(prompt_border)

    prompt_label = Label.new()
    prompt_label.name = "KickButtonLabel"
    prompt_label.position = Vector2(-78.0, -16.0)
    prompt_label.size = Vector2(156.0, 32.0)
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt_label.text = "[ J / K ]  KICK"
    prompt_label.add_theme_font_size_override("font_size", 16)
    prompt_label.add_theme_color_override(
        "font_color",
        Color("c6f6ff")
    )
    prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button_prompt.add_child(prompt_label)


func _update_button_prompt() -> void:
    if button_prompt == null or not is_instance_valid(button_prompt):
        return

    var player_node := _get_player()
    var player_is_near := (
        player_node != null
        and is_instance_valid(player_node)
        and player_node.global_position.distance_to(global_position)
        <= prompt_distance
    )

    button_prompt.visible = (
        orb_enabled
        and not GameState.dialogue_active
        and player_is_near
    )

    if pressed:
        prompt_label.text = "ACTIVATED"
        prompt_background.color = Color(0.04, 0.18, 0.14, 0.95)
        prompt_border.default_color = Color("7effb2")
        prompt_label.add_theme_color_override(
            "font_color",
            Color("bfffd4")
        )
    else:
        prompt_label.text = "[ J / K ]  KICK"
        prompt_background.color = Color(0.035, 0.075, 0.12, 0.94)
        prompt_border.default_color = Color("65dfff")
        prompt_label.add_theme_color_override(
            "font_color",
            Color("c6f6ff")
        )


func _play_press_feedback() -> void:
    modulate = Color("9dffbc")

    if orb_visual == null or not is_instance_valid(orb_visual):
        return

    var tween := create_tween()
    tween.tween_property(
        orb_visual,
        "scale",
        Vector2(0.78, 0.78),
        0.08
    )
    tween.tween_property(
        orb_visual,
        "scale",
        Vector2.ONE,
        0.14
    ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
