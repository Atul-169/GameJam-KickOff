class_name BreakablePillar
extends StaticBody2D

signal broken(position: Vector2)

@export var fall_direction := 1
var broken_once := false
var start_rotation := 0.0
var world_active := false
var break_generation := 0
var active_tween: Tween

func _ready() -> void:
    start_rotation = rotation
    add_child(
        AssetRegistry.make_visual(
            "breakable_pillar", Vector2(82, 300), Color("7c786f"), "PILLAR"
        )
    )
    add_to_group("resettable")
    add_to_group("freezable")
    set_world_active(false)

func set_world_active(active: bool) -> void:
    world_active = active
    if world_active:
        collision_layer = CollisionLayers.WORLD
        collision_mask = (
            CollisionLayers.PLAYER
            | CollisionLayers.ENEMY
            | CollisionLayers.PROJECTILE
        )
    else:
        break_generation += 1
        if active_tween != null and active_tween.is_valid():
            active_tween.kill()
        collision_layer = CollisionLayers.WORLD
        collision_mask = CollisionLayers.PLAYER | CollisionLayers.ENEMY

func receive_projectile(reflected: bool, _source: Node = null) -> void:
    if world_active and reflected:
        break_pillar()

func receive_explosion(_damage: int, _origin: Vector2) -> void:
    if world_active:
        break_pillar()

func receive_heavy_impact() -> void:
    if world_active:
        break_pillar()

func break_pillar() -> void:
    if not world_active or broken_once:
        return
    break_generation += 1
    var token := break_generation
    broken_once = true
    modulate = Color("ffb17c")
    await get_tree().create_timer(0.55).timeout
    if token != break_generation or not world_active or not is_inside_tree():
        return
    active_tween = create_tween()
    active_tween.tween_property(
        self, "rotation", float(fall_direction) * 1.42, 0.55
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    await active_tween.finished
    if token != break_generation or not world_active or not is_inside_tree():
        return
    var stun_zone := Area2D.new()
    stun_zone.collision_layer = 0
    stun_zone.collision_mask = CollisionLayers.ENEMY
    var shape_node := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(280, 120)
    shape_node.shape = rectangle
    stun_zone.add_child(shape_node)
    get_parent().add_child(stun_zone)
    stun_zone.global_position = (
        global_position + Vector2(float(fall_direction) * 125.0, -55.0)
    )
    await get_tree().physics_frame
    if token != break_generation or not world_active or not is_inside_tree():
        stun_zone.queue_free()
        return
    for body: Node in stun_zone.get_overlapping_bodies():
        if body.has_method("stun"):
            body.call("stun", 1.5)
    stun_zone.queue_free()
    broken.emit(global_position)

func reset_state() -> void:
    break_generation += 1
    if active_tween != null and active_tween.is_valid():
        active_tween.kill()
    active_tween = null
    broken_once = false
    rotation = start_rotation
    modulate = Color.WHITE
    set_world_active(false)
