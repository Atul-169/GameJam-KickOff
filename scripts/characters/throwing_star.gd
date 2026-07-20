class_name PlayerThrowingStar
extends Area2D

@export var speed := 760.0
@export var life_time := 2.2

var direction := Vector2.RIGHT
var damage := 1
var source: Node
var spent := false

func _ready() -> void:
    collision_layer = CollisionLayers.PROJECTILE
    collision_mask = CollisionLayers.WORLD | CollisionLayers.ENEMY
    monitoring = true
    monitorable = true
    body_entered.connect(_on_body_entered)
    add_to_group("temporary")

func launch(direction_value: Vector2, source_value: Node, damage_value: int = 1) -> void:
    direction = direction_value.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    source = source_value
    damage = maxi(damage_value, 1)
    rotation = direction.angle()

func _physics_process(delta: float) -> void:
    if spent:
        return
    global_position += direction * speed * delta
    rotation += 12.0 * delta
    life_time -= delta
    if life_time <= 0.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if spent or body == source:
        return
    spent = true
    if body.has_method("receive_weapon_hit"):
        body.call("receive_weapon_hit", damage, direction, "star", source)
    _impact_flash()
    set_deferred("monitoring", false)
    var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if shape != null:
        shape.set_deferred("disabled", true)
    visible = false
    await get_tree().create_timer(0.04).timeout
    if is_inside_tree():
        queue_free()

func _impact_flash() -> void:
    var parent_node := get_parent()
    if parent_node == null:
        return
    var flash := Polygon2D.new()
    flash.polygon = PackedVector2Array([
        Vector2(-18, 0), Vector2(0, -18), Vector2(18, 0), Vector2(0, 18)
    ])
    flash.color = Color(0.95, 0.88, 0.38, 0.85)
    flash.z_index = 30
    parent_node.add_child(flash)
    flash.global_position = global_position
    var tween := flash.create_tween()
    tween.set_parallel(true)
    tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.14)
    tween.tween_property(flash, "modulate:a", 0.0, 0.14)
    tween.chain().tween_callback(flash.queue_free)
