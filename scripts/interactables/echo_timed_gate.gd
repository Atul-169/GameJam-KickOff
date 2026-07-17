class_name EchoTimedGate
extends AnimatableBody2D

signal opened
signal closed

@export var travel_distance := 360.0
var closed_position := Vector2.ZERO
var open_position := Vector2.ZERO
var world_active := false
var is_open := false
var permanent := false
var time_remaining := 0.0
var moving := false
var visual_root: Node2D
var timer_label: Label

func _ready() -> void:
    collision_layer = CollisionLayers.WORLD
    collision_mask = CollisionLayers.PLAYER | CollisionLayers.KICKABLE
    closed_position = position
    open_position = position + Vector2(0, -travel_distance)
    visual_root = AssetRegistry.make_visual(
        "echo_timed_gate",
        Vector2(110, 390),
        Color("66528f"),
        "ECHO GATE",
    )
    add_child(visual_root)
    timer_label = Label.new()
    timer_label.position = Vector2(-75, -240)
    timer_label.size = Vector2(150, 40)
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timer_label.add_theme_font_size_override("font_size", 20)
    timer_label.add_theme_color_override("font_color", Color("8cecff"))
    timer_label.visible = false
    add_child(timer_label)
    add_to_group("resettable")

func _process(delta: float) -> void:
    if not world_active or not is_open or permanent:
        return
    time_remaining = maxf(time_remaining - delta, 0.0)
    timer_label.text = "%.1f" % time_remaining
    if time_remaining <= 1.2:
        visual_root.modulate = Color("ff9b8f")
    if time_remaining <= 0.0 and not moving:
        if _doorway_clear():
            _close_gate()
        else:
            time_remaining = 0.25

func set_world_active(active: bool) -> void:
    world_active = active
    if not active and not permanent:
        time_remaining = 0.0

func open_temporarily(duration: float = 4.2) -> void:
    if not world_active or permanent:
        return
    time_remaining = maxf(duration, 0.5)
    if is_open or moving:
        timer_label.visible = true
        return
    moving = true
    timer_label.visible = true
    var tween := create_tween()
    tween.tween_property(self, "position", open_position, 0.35)
    tween.tween_callback(_finish_open)

func open_permanently() -> void:
    permanent = true
    world_active = false
    time_remaining = 0.0
    timer_label.visible = false
    if is_open:
        return
    moving = true
    var tween := create_tween()
    tween.tween_property(self, "position", open_position, 0.35)
    tween.tween_callback(_finish_open)

func reset_state() -> void:
    permanent = false
    world_active = false
    is_open = false
    moving = false
    time_remaining = 0.0
    position = closed_position
    timer_label.visible = false
    visual_root.modulate = Color.WHITE

func _finish_open() -> void:
    moving = false
    is_open = true
    opened.emit()
    AudioManager.play_sfx("gate_open_sfx")

func _close_gate() -> void:
    moving = true
    timer_label.visible = false
    var tween := create_tween()
    tween.tween_property(self, "position", closed_position, 0.32)
    tween.tween_callback(_finish_close)

func _finish_close() -> void:
    moving = false
    is_open = false
    visual_root.modulate = Color.WHITE
    closed.emit()

func _doorway_clear() -> bool:
    for group_name in ["player", "echo_orb"]:
        var node := get_tree().get_first_node_in_group(group_name) as Node2D
        if node != null and is_instance_valid(node):
            if absf(node.global_position.x - closed_position.x) < 115.0:
                return false
    return true
