class_name RuneJar
extends CharacterBody2D

signal exploded(position: Vector2)

var velocity_external := Vector2.ZERO
var armed := false
var exploded_once := false
var spawn_position := Vector2.ZERO
var world_active := false
var explosion_generation := 0

func _ready() -> void:
    spawn_position = global_position
    add_child(
        AssetRegistry.make_visual(
            "rune_jar", Vector2(54, 72), Color("f090b8"), "RUNE"
        )
    )
    add_to_group("resettable")
    add_to_group("freezable")
    set_world_active(false)

func set_world_active(active: bool) -> void:
    world_active = active
    if world_active and not exploded_once:
        collision_layer = CollisionLayers.KICKABLE
        collision_mask = CollisionLayers.WORLD | CollisionLayers.ENEMY
    else:
        explosion_generation += 1
        collision_layer = 0
        collision_mask = 0
        velocity_external = Vector2.ZERO
        armed = false
        modulate = Color.WHITE

func _physics_process(delta: float) -> void:
    if not world_active or exploded_once:
        return
    velocity_external.y += 1100.0 * delta
    var collision := move_and_collide(velocity_external * delta)
    if collision != null:
        if armed and velocity_external.length() > 260.0:
            explode()
        else:
            velocity_external = velocity_external.bounce(
                collision.get_normal()
            ) * 0.35

func receive_kick(
    force: float,
    _damage: int,
    direction: Vector2,
    _charged: bool,
    _source: Node
) -> void:
    if not world_active or exploded_once:
        return
    armed = true
    modulate = Color("ffca60")
    velocity_external = (
        (direction + Vector2(0, -0.25)).normalized() * force * 0.75
    )

func receive_enemy_impact(speed: float, _origin: Vector2) -> void:
    if not world_active or exploded_once:
        return
    if speed > 280.0:
        armed = true
        explode()

func explode() -> void:
    if not world_active or exploded_once:
        return
    explosion_generation += 1
    var token := explosion_generation
    exploded_once = true
    visible = false
    collision_layer = 0
    collision_mask = 0

    var blast := Area2D.new()
    blast.collision_layer = CollisionLayers.HAZARD
    blast.collision_mask = CollisionLayers.ENEMY
    var shape_node := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 150.0
    shape_node.shape = circle
    blast.add_child(shape_node)
    get_parent().add_child(blast)
    blast.global_position = global_position

    var flash := Polygon2D.new()
    var points := PackedVector2Array()
    for i in 24:
        points.append(Vector2.from_angle(float(i) / 24.0 * TAU) * 145.0)
    flash.polygon = points
    flash.color = Color(1.0, 0.65, 0.18, 0.7)
    blast.add_child(flash)

    await get_tree().physics_frame
    if token != explosion_generation or not world_active or not is_inside_tree():
        if is_instance_valid(blast):
            blast.queue_free()
        return
    for body in blast.get_overlapping_bodies():
        if body.has_method("receive_explosion"):
            body.call("receive_explosion", 2, global_position)
    exploded.emit(global_position)
    var tween := blast.create_tween()
    tween.tween_property(blast, "modulate:a", 0.0, 0.28)
    tween.tween_callback(blast.queue_free)

func reset_state() -> void:
    explosion_generation += 1
    exploded_once = false
    armed = false
    visible = true
    global_position = spawn_position
    velocity_external = Vector2.ZERO
    modulate = Color.WHITE
    set_world_active(false)
