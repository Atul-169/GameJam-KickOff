class_name EchoShockwave
extends Node2D

@export var speed := 520.0
@export var lifetime := 2.6
var active := false
var life_left := 0.0
var left_wave: Area2D
var right_wave: Area2D
var hit_ids: Dictionary = {}

func _ready() -> void:
    left_wave = _make_wave("LeftWave", -1.0)
    right_wave = _make_wave("RightWave", 1.0)
    add_child(left_wave)
    add_child(right_wave)
    add_to_group("temporary")
    add_to_group("freezable")
    set_world_active(false)

func launch() -> void:
    life_left = lifetime
    hit_ids.clear()
    set_world_active(true)

func set_world_active(value: bool) -> void:
    active = value
    for wave in [left_wave, right_wave]:
        if wave == null:
            continue
        wave.monitoring = value
        wave.monitorable = value
        wave.collision_layer = CollisionLayers.ENEMY_ATTACK if value else 0
        wave.collision_mask = CollisionLayers.PLAYER if value else 0
        wave.visible = value

func _physics_process(delta: float) -> void:
    if not active:
        return
    life_left -= delta
    left_wave.position.x -= speed * delta
    right_wave.position.x += speed * delta
    if life_left <= 0.0:
        queue_free()

func _make_wave(node_name: String, direction: float) -> Area2D:
    var area := Area2D.new()
    area.name = node_name
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(90, 34)
    collision.shape = shape
    area.add_child(collision)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-45, 16),
        Vector2(45, 16),
        Vector2(30 * direction, -16),
        Vector2(-30 * direction, -16),
    ])
    visual.color = Color(0.45, 0.9, 1.0, 0.72)
    area.add_child(visual)
    area.body_entered.connect(_body_entered)
    return area

func _body_entered(body: Node) -> void:
    if not active or not (body is ArinController):
        return
    var body_id := body.get_instance_id()
    if hit_ids.has(body_id):
        return
    hit_ids[body_id] = true
    var push_direction := signf(body.global_position.x - global_position.x)
    body.take_damage(1, Vector2(push_direction * 220.0, -80.0))
