class_name EnemyBase
extends CharacterBody2D

signal defeated(enemy: EnemyBase)
signal health_changed(current: int, maximum: int)

@export var enemy_id: String = "enemy"
@export var max_health: int = 3
@export var move_speed: float = 90.0
@export var gravity: float = 1150.0
@export var contact_damage: int = 1
@export var asset_key: String = "stone_guardian"
@export var caption: String = "GUARDIAN"
@export var tint: Color = Color("7d8790")

var target: ArinController
var world_active := false
var dead := false
var invulnerable := false
var attack_cooldown := 0.0
var knockback := Vector2.ZERO
var stunned := false
var stun_generation := 0

@onready var health: HealthComponent = $HealthComponent
@onready var visual_root: Node2D = $VisualRoot

func _ready() -> void:
    add_to_group("enemy")
    add_to_group("freezable")
    add_to_group("resettable")
    health.setup(max_health)
    health.died.connect(_die)
    health.health_changed.connect(
        func(current: int, maximum: int) -> void:
            health_changed.emit(current, maximum)
    )
    visual_root.add_child(
        AssetRegistry.make_visual(asset_key, Vector2(70, 92), tint, caption)
    )

func set_target(value: ArinController) -> void:
    target = value

func set_world_active(value: bool) -> void:
    world_active = value
    if not world_active:
        stun_generation += 1
        stunned = false
        velocity = Vector2.ZERO
        knockback = Vector2.ZERO

func can_receive_combat_effects() -> bool:
    return world_active and not dead

func _physics_process(delta: float) -> void:
    if dead:
        return
    if not world_active:
        velocity = Vector2.ZERO
        return
    if not is_on_floor():
        velocity.y += gravity * delta
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    if stunned:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
    elif knockback.length() > 8.0:
        velocity.x = knockback.x
        velocity.y = minf(velocity.y, knockback.y)
        knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
    else:
        think(delta)
    var impact_speed := velocity.length()
    move_and_slide()
    if impact_speed > 280.0 and world_active:
        for index in get_slide_collision_count():
            var collider := get_slide_collision(index).get_collider()
            if collider == null:
                continue
            if collider.has_method("receive_heavy_impact"):
                collider.call("receive_heavy_impact")
            if collider.has_method("receive_enemy_impact"):
                collider.call(
                    "receive_enemy_impact", impact_speed, global_position
                )
            if collider is EnemyBase and collider != self:
                collider.receive_heavy_collision(global_position)
    if global_position.y > 1400.0:
        _die()

func think(_delta: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    velocity.x = signf(target.global_position.x - global_position.x) * move_speed

func receive_kick(
    force: float,
    damage: int,
    direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if not can_receive_combat_effects():
        return
    health.damage(damage)
    knockback = direction * force * 0.52 + Vector2(0, -100)
    _hit_feedback(charged)

func receive_projectile(reflected: bool, _source: Node = null) -> void:
    if not can_receive_combat_effects() or not reflected:
        return
    health.damage(2)
    _hit_feedback(true)

func receive_explosion(damage: int, origin: Vector2) -> void:
    if not can_receive_combat_effects():
        return
    health.damage(damage)
    knockback = (
        origin.direction_to(global_position) * 420.0 + Vector2(0, -160)
    )
    _hit_feedback(true)

func receive_heavy_collision(origin: Vector2) -> void:
    if not can_receive_combat_effects():
        return
    health.damage(1)
    knockback = (
        origin.direction_to(global_position) * 260.0 + Vector2(0, -90)
    )
    _hit_feedback(true)

func stun(duration: float) -> void:
    if not can_receive_combat_effects() or stunned:
        return
    stun_generation += 1
    var token := stun_generation
    stunned = true
    velocity = Vector2.ZERO
    await get_tree().create_timer(maxf(duration, 0.05)).timeout
    if (
        token == stun_generation
        and is_inside_tree()
        and world_active
        and not dead
    ):
        stunned = false

func _hit_feedback(strong: bool) -> void:
    if not can_receive_combat_effects():
        return
    modulate = Color("fff0a3")
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.16)
    if strong and target != null and is_instance_valid(target):
        target._camera_shake(5.0)

func _die() -> void:
    if dead or not world_active:
        return
    dead = true
    collision_layer = 0
    collision_mask = 0
    world_active = false
    defeated.emit(self)
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(queue_free)

func reset_state() -> void:
    stun_generation += 1
    dead = false
    world_active = false
    stunned = false
    health.reset()
    velocity = Vector2.ZERO
    knockback = Vector2.ZERO
    attack_cooldown = 0.0
    modulate = Color.WHITE
    collision_layer = CollisionLayers.ENEMY
    collision_mask = (
        CollisionLayers.WORLD
        | CollisionLayers.PLAYER
        | CollisionLayers.ENEMY
        | CollisionLayers.KICKABLE
    )
