class_name TargetZone
extends Area2D

signal reached(index: int, body: Node)

@export var target_index := 0
@export var caption := "TARGET"
var enabled := true
var completed := false

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.KICKABLE
    monitoring = true
    body_entered.connect(_entered)

    var ring := Line2D.new()
    ring.width = 7.0
    ring.default_color = Color("ffd54f")
    var points := PackedVector2Array()
    for i in 25:
        points.append(Vector2.from_angle(float(i) / 24.0 * TAU) * 62.0)
    ring.points = points
    add_child(ring)

    var label := Label.new()
    label.text = caption
    label.position = Vector2(-80, -100)
    label.size = Vector2(160, 28)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    add_child(label)

func _entered(body: Node) -> void:
    if not enabled or completed or not body is Football:
        return
    completed = true
    modulate = Color("66ff99")
    reached.emit(target_index, body)

func set_enabled(value: bool) -> void:
    enabled = value
    modulate = Color.WHITE if value else Color("6c6c74")
    if value:
        call_deferred("_check_current_overlap")

func _check_current_overlap() -> void:
    if not enabled or completed:
        return
    for body in get_overlapping_bodies():
        if body is Football:
            _entered(body)
            return

func reset_state() -> void:
    completed = false
    modulate = Color.WHITE
