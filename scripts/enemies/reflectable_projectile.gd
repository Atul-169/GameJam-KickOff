class_name ReflectableProjectile
extends Area2D

var velocity := Vector2.ZERO
var active := false
var reflected := false
var reflectable := false
var reflectable_on_activation := false
var life := 7.0
var owner_enemy: Node
var visual: Polygon2D
var activation_generation := 0

func _ready() -> void:
    body_entered.connect(_body_entered)
    area_entered.connect(_area_entered)
    visual = Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-18, -12), Vector2(20, 0), Vector2(-18, 12)
    ])
    visual.color = Color("ef5350")
    add_child(visual)
    var trail_texture := AssetRegistry.load_texture("projectile_trail")
    if trail_texture != null:
        var trail_sprite := Sprite2D.new()
        trail_sprite.texture = trail_texture
        trail_sprite.position = Vector2(-24, 0)
        trail_sprite.z_index = -1
        add_child(trail_sprite)
    add_to_group("freezable")
    add_to_group("temporary")
    _set_collision_enabled(false)

func launch(value: Vector2, source: Node) -> void:
    activation_generation += 1
    var token := activation_generation
    velocity = value
    owner_enemy = source
    active = true
    reflected = false
    reflectable = false
    reflectable_on_activation = false
    _set_collision_enabled(true)
    visual.modulate = Color("ff6b6b")
    await get_tree().create_timer(0.45).timeout
    if token != activation_generation or not active or not is_inside_tree():
        return
    reflectable = true
    visual.color = Color("ffe082")
    var tween := create_tween().set_loops()
    tween.tween_property(visual, "scale", Vector2(1.25, 1.25), 0.12)
    tween.tween_property(visual, "scale", Vector2.ONE, 0.12)

func configure_suspended(value: Vector2, can_reflect: bool = true) -> void:
    velocity = value
    reflectable_on_activation = can_reflect
    reflected = false
    set_world_active(false)

func set_world_active(value: bool) -> void:
    activation_generation += 1
    active = value
    if active:
        _set_collision_enabled(true)
        reflectable = reflectable_on_activation
        visual.color = Color("ffe082") if reflectable else Color("ff6b6b")
    else:
        if reflectable:
            reflectable_on_activation = true
        reflectable = false
        _set_collision_enabled(false)

func _set_collision_enabled(value: bool) -> void:
    monitoring = value
    monitorable = value
    collision_layer = CollisionLayers.PROJECTILE if value else 0
    collision_mask = (
        CollisionLayers.WORLD
        | CollisionLayers.PLAYER
        | CollisionLayers.ENEMY
        | CollisionLayers.TRIGGER
        if value
        else 0
    )

func _physics_process(delta: float) -> void:
    if not active:
        return
    position += velocity * delta
    life -= delta
    rotation = velocity.angle()
    if life <= 0.0:
        queue_free()

func receive_kick(
    force: float,
    _damage: int,
    direction: Vector2,
    _charged: bool,
    source: Node
) -> void:
    if not active or not reflectable or reflected:
        return
    reflected = true
    visual.color = Color("65e7ff")
    collision_mask = (
        CollisionLayers.WORLD
        | CollisionLayers.ENEMY
        | CollisionLayers.TRIGGER
    )
    var target_point := global_position + direction * 600.0
    var level := get_tree().get_first_node_in_group("level_manager")
    if level != null and level.has_method("get_reflect_target"):
        target_point = level.call("get_reflect_target")
    velocity = (
        global_position.direction_to(target_point) * maxf(force * 0.72, 520.0)
    )
    owner_enemy = source
    AudioManager.play_sfx("projectile_reflect_sfx")

func is_reflected() -> bool:
    return reflected

func _body_entered(body: Node) -> void:
    if not active or body == owner_enemy:
        return
    if body is ArinController and not reflected:
        body.take_damage(1, velocity.normalized() * 220.0)
        queue_free()
    elif reflected and body is EnemyBase:
        body.receive_projectile(true, self)
        queue_free()
    elif reflected and body.has_method("receive_projectile"):
        body.call("receive_projectile", true, self)
        queue_free()
    elif body is StaticBody2D:
        queue_free()

func _area_entered(area: Area2D) -> void:
    if not active:
        return
    if reflected and area.has_method("receive_projectile"):
        area.call("receive_projectile", true, self)
        queue_free()
