class_name EnemyHealthBar
extends Node2D

@export var bar_size := Vector2(124.0, 14.0)

var display_name := "ENEMY"
var current_health := 1
var max_health := 1
var background: ColorRect
var fill: ColorRect
var name_label: Label

func _ready() -> void:
    z_index = 100
    z_as_relative = false
    _build_visuals()
    _refresh()

func setup(name_value: String, maximum: int, current: int = -1) -> void:
    display_name = name_value.to_upper()
    max_health = maxi(maximum, 1)
    current_health = max_health if current < 0 else clampi(current, 0, max_health)
    if is_node_ready():
        _refresh()

func update_health(current: int, maximum: int) -> void:
    max_health = maxi(maximum, 1)
    current_health = clampi(current, 0, max_health)
    if is_node_ready():
        _refresh()
        _pulse()

func _build_visuals() -> void:
    var outline := ColorRect.new()
    outline.position = Vector2(-bar_size.x * 0.5 - 2.0, -2.0)
    outline.size = bar_size + Vector2(4.0, 4.0)
    outline.color = Color(0.02, 0.025, 0.04, 0.95)
    add_child(outline)

    background = ColorRect.new()
    background.position = Vector2(-bar_size.x * 0.5, 0.0)
    background.size = bar_size
    background.color = Color(0.16, 0.06, 0.08, 0.94)
    add_child(background)

    fill = ColorRect.new()
    fill.position = Vector2(-bar_size.x * 0.5, 0.0)
    fill.size = bar_size
    fill.color = Color(0.92, 0.18, 0.22, 0.98)
    add_child(fill)

    name_label = Label.new()
    name_label.position = Vector2(-bar_size.x * 0.75, -27.0)
    name_label.size = Vector2(bar_size.x * 1.5, 24.0)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 14)
    name_label.add_theme_color_override("font_color", Color("fff2dc"))
    name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    name_label.add_theme_constant_override("shadow_offset_x", 2)
    name_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(name_label)

func _refresh() -> void:
    if fill == null or name_label == null:
        return
    var ratio := clampf(float(current_health) / float(max_health), 0.0, 1.0)
    fill.size.x = bar_size.x * ratio
    if ratio > 0.55:
        fill.color = Color(0.20, 0.84, 0.36, 0.98)
    elif ratio > 0.25:
        fill.color = Color(1.0, 0.68, 0.16, 0.98)
    else:
        fill.color = Color(0.95, 0.16, 0.20, 0.98)
    name_label.text = "%s  %d/%d" % [display_name, current_health, max_health]
    visible = current_health > 0

func _pulse() -> void:
    scale = Vector2(1.08, 1.08)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, 0.12)
