class_name EchoOrb
extends CharacterBody2D

signal kicked_off

@export var max_speed := 820.0
@export var drag := 35.0
@export var stopped_reset_delay := 2.2
@export var aim_change_distance := 360.0

# W / Up moves toward negative angles; S / Down moves toward positive angles.
# Godot's positive Y points downward, so negative angles aim upward.
var aim_angles_degrees: Array[float] = [
    -60.0,
    -45.0,
    -30.0,
    -15.0,
    0.0,
    15.0,
    30.0,
    45.0,
    60.0,
]
var aim_index := 4

var spawn_position := Vector2.ZERO
var reset_bounds := Rect2(-200, -200, 5000, 1500)
var active := false
var orb_enabled := true
var still_time := 0.0
var trail: Line2D
var trail_points := PackedVector2Array()

var aim_indicator: Node2D
var aim_arrow: Node2D
var aim_line: Line2D
var aim_head: Polygon2D
var aim_label: Label
var aim_hint_label: Label


func _ready() -> void:
    collision_layer = CollisionLayers.KICKABLE
    collision_mask = CollisionLayers.WORLD | CollisionLayers.TRIGGER
    spawn_position = global_position

    add_child(
        AssetRegistry.make_visual(
            "echo_orb",
            Vector2(48, 48),
            Color("70d6ff"),
            ""
        )
    )

    trail = Line2D.new()
    trail.width = 6.0
    trail.default_color = Color(0.35, 0.82, 1.0, 0.45)
    trail.z_index = -1
    get_parent().call_deferred("add_child", trail)

    _build_aim_indicator()
    _update_aim_indicator()

    add_to_group("resettable")
    add_to_group("echo_orb")


func _unhandled_input(event: InputEvent) -> void:
    if not _player_can_adjust_aim():
        return

    var key_event := event as InputEventKey
    if key_event == null or not key_event.pressed or key_event.echo:
        return

    var logical_code := key_event.keycode
    var physical_code := key_event.physical_keycode

    if (
        logical_code == KEY_W
        or physical_code == KEY_W
        or logical_code == KEY_UP
        or physical_code == KEY_UP
    ):
        _change_aim(-1)
        get_viewport().set_input_as_handled()
    elif (
        logical_code == KEY_S
        or physical_code == KEY_S
        or logical_code == KEY_DOWN
        or physical_code == KEY_DOWN
    ):
        _change_aim(1)
        get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
    _update_aim_indicator()

    if not active:
        return

    var collision := move_and_collide(velocity * delta)
    if collision != null:
        velocity = velocity.bounce(collision.get_normal()) * 0.94
        global_position += collision.get_normal() * 2.0

    velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
    velocity = velocity.limit_length(max_speed)

    if trail != null and is_instance_valid(trail):
        trail_points.append(global_position)
        while trail_points.size() > 16:
            trail_points.remove_at(0)
        trail.points = trail_points

    if velocity.length() < 18.0:
        still_time += delta
    else:
        still_time = 0.0

    if (
        still_time >= stopped_reset_delay
        or not reset_bounds.has_point(global_position)
    ):
        reset_orb()


func receive_kick(
    force: float,
    _damage: int,
    direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if not orb_enabled:
        return
    active = true
    still_time = 0.0

    var multiplier := 0.8 if charged else 0.72
    var launch_direction := direction.normalized()

    if _source is ArinController:
        launch_direction = _selected_aim_direction(_source as Node2D)

    velocity = launch_direction * minf(
        force * multiplier,
        max_speed
    )

    _update_aim_indicator()
    kicked_off.emit()


func shadow_kick(direction: Vector2, charged: bool) -> void:
    var force := 760.0 if charged else 470.0
    receive_kick(force, 0, direction, charged, self)


func set_pedestal(position_value: Vector2) -> void:
    spawn_position = position_value
    reset_orb()


func set_reset_bounds(bounds: Rect2) -> void:
    reset_bounds = bounds


func set_orb_enabled(enabled: bool) -> void:
    orb_enabled = enabled
    if enabled:
        collision_layer = CollisionLayers.KICKABLE
        collision_mask = CollisionLayers.WORLD | CollisionLayers.TRIGGER
    else:
        collision_layer = 0
        collision_mask = 0
        active = false
        velocity = Vector2.ZERO
    _update_aim_indicator()


func reset_orb() -> void:
    global_position = spawn_position
    velocity = Vector2.ZERO
    active = false
    still_time = 0.0
    trail_points.clear()

    if trail != null:
        trail.clear_points()

    _update_aim_indicator()


func reset_state() -> void:
    aim_index = 4
    set_orb_enabled(true)
    reset_orb()


func _change_aim(step: int) -> void:
    var previous_index := aim_index
    aim_index = clampi(
        aim_index + step,
        0,
        aim_angles_degrees.size() - 1
    )

    if aim_index != previous_index:
        AudioManager.play_sfx("menu_move_sfx")

    _update_aim_indicator()


func _selected_aim_direction(source: Node2D) -> Vector2:
    var horizontal := (
        1.0
        if source.global_position.x <= global_position.x
        else -1.0
    )

    var selected_angle := aim_angles_degrees[aim_index]

    # Mirror the angle when Arin stands on the right side of the orb.
    # This keeps "UP" pointing upward in both left-facing and right-facing kicks.
    return Vector2(horizontal, 0.0).rotated(
        deg_to_rad(selected_angle * horizontal)
    ).normalized()


func _get_player() -> Node2D:
    return get_tree().get_first_node_in_group("player") as Node2D


func _player_can_adjust_aim() -> bool:
    if not orb_enabled or active or GameState.dialogue_active:
        return false

    var player_node := _get_player()
    if player_node == null or not is_instance_valid(player_node):
        return false

    return (
        player_node.global_position.distance_to(global_position)
        <= aim_change_distance
    )


func _build_aim_indicator() -> void:
    aim_indicator = Node2D.new()
    aim_indicator.name = "AimIndicator"
    aim_indicator.z_index = 20
    add_child(aim_indicator)

    aim_arrow = Node2D.new()
    aim_arrow.name = "AimArrow"
    aim_indicator.add_child(aim_arrow)

    aim_line = Line2D.new()
    aim_line.width = 5.0
    aim_line.default_color = Color("8cecff")
    aim_line.points = PackedVector2Array([
        Vector2.ZERO,
        Vector2(84.0, 0.0),
    ])
    aim_arrow.add_child(aim_line)

    aim_head = Polygon2D.new()
    aim_head.polygon = PackedVector2Array([
        Vector2(84.0, 0.0),
        Vector2(68.0, -10.0),
        Vector2(68.0, 10.0),
    ])
    aim_head.color = Color("8cecff")
    aim_arrow.add_child(aim_head)

    aim_label = Label.new()
    aim_label.name = "AimLabel"
    aim_label.position = Vector2(-105.0, -116.0)
    aim_label.size = Vector2(210.0, 34.0)
    aim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    aim_label.add_theme_font_size_override("font_size", 20)
    aim_label.add_theme_color_override(
        "font_color",
        Color("baf4ff")
    )
    aim_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    aim_indicator.add_child(aim_label)

    aim_hint_label = Label.new()
    aim_hint_label.name = "AimHint"
    aim_hint_label.position = Vector2(-145.0, -88.0)
    aim_hint_label.size = Vector2(290.0, 30.0)
    aim_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    aim_hint_label.text = "W / UP: AIM UP    S / DOWN: AIM DOWN"
    aim_hint_label.add_theme_font_size_override("font_size", 14)
    aim_hint_label.add_theme_color_override(
        "font_color",
        Color("9ac8d7")
    )
    aim_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    aim_indicator.add_child(aim_hint_label)


func _update_aim_indicator() -> void:
    if aim_indicator == null or not is_instance_valid(aim_indicator):
        return

    var player_node := _get_player()
    var can_show := (
        orb_enabled
        and not active
        and not GameState.dialogue_active
        and player_node != null
        and is_instance_valid(player_node)
        and (
            player_node.global_position.distance_to(global_position)
            <= aim_change_distance
        )
    )

    aim_indicator.visible = can_show

    if not can_show:
        return

    var direction := _selected_aim_direction(player_node)
    aim_arrow.rotation = direction.angle()

    var selected_angle := aim_angles_degrees[aim_index]
    if is_zero_approx(selected_angle):
        aim_label.text = "AIM: STRAIGHT (0°)"
    elif selected_angle < 0.0:
        aim_label.text = "AIM: UP (%d°)" % int(absf(selected_angle))
    else:
        aim_label.text = "AIM: DOWN (%d°)" % int(selected_angle)
