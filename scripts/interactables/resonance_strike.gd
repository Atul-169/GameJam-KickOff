class_name ResonanceStrike
extends Area2D

@export var lifetime := 0.20
var charged := true
var consumed := false
var generation := 0

func _ready() -> void:
    collision_layer = CollisionLayers.PLAYER_KICK
    collision_mask = CollisionLayers.ENEMY | CollisionLayers.TRIGGER
    monitoring = true
    monitorable = true
    area_entered.connect(_area_entered)
    body_entered.connect(_body_entered)
    add_to_group("temporary")
    _build_visual()
    generation += 1
    var token := generation
    await get_tree().create_timer(lifetime).timeout
    if token == generation and is_inside_tree():
        queue_free()

func configure(is_charged: bool) -> void:
    charged = is_charged

func is_resonance_strike() -> bool:
    return charged and not consumed

func consume() -> void:
    consumed = true
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)

func _area_entered(area: Area2D) -> void:
    if consumed:
        return
    if area.has_method("receive_resonance_strike"):
        area.call("receive_resonance_strike", self)

func _body_entered(body: Node) -> void:
    if consumed:
        return
    if body.has_method("receive_resonance_strike"):
        body.call("receive_resonance_strike", self)

func _build_visual() -> void:
    var ring := Line2D.new()
    ring.width = 8.0
    ring.default_color = Color(0.35, 0.95, 1.0, 0.85)
    var points := PackedVector2Array()
    for index in 25:
        points.append(Vector2.from_angle(float(index) / 24.0 * TAU) * 58.0)
    ring.points = points
    add_child(ring)
    var core := Polygon2D.new()
    core.polygon = PackedVector2Array([
        Vector2(-24, -12),
        Vector2(24, -12),
        Vector2(34, 0),
        Vector2(24, 12),
        Vector2(-24, 12),
        Vector2(-34, 0),
    ])
    core.color = Color(0.55, 0.95, 1.0, 0.55)
    add_child(core)
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.45, 1.45), lifetime)
    tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
