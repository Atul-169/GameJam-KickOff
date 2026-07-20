class_name GatekeeperBoss
extends CharacterBody2D

signal defeated
signal health_changed(current: int, maximum: int)
signal shield_changed(enabled: bool)

var target: ArinController
var health := 12
var max_health := 12
var shielded := true
var world_active := false
var shoot_timer := 1.0
var ground_timer := 3.0
var rune_count := 0
var shield_window_running := false
var defeated_once := false
var phase_generation := 0

@onready var core: Node2D = $Core
var health_bar: EnemyHealthBar

func _ready() -> void:
    add_to_group("enemy")
    add_to_group("freezable")
    add_to_group("resettable")
    $VisualRoot.add_child(
        AssetRegistry.make_visual(
            "gatekeeper", Vector2(130, 170), Color("9a6d38"), "GATEKEEPER"
        )
    )
    core.visible = false
    health_bar = EnemyHealthBar.new()
    health_bar.position = Vector2(0, -205)
    health_bar.bar_size = Vector2(158, 16)
    add_child(health_bar)
    health_bar.setup("GATEKEEPER", max_health, health)
    health_changed.connect(health_bar.update_health)

func set_target(value: ArinController) -> void:
    target = value

func set_world_active(value: bool) -> void:
    world_active = value
    if not world_active:
        phase_generation += 1
        velocity = Vector2.ZERO

func can_receive_combat_effects() -> bool:
    return world_active and health > 0 and not defeated_once

func _physics_process(delta: float) -> void:
    if not world_active or defeated_once:
        velocity = Vector2.ZERO
        return
    if not is_on_floor():
        velocity.y += 1100.0 * delta
    if target != null:
        shoot_timer -= delta
        ground_timer -= delta
        var dx := target.global_position.x - global_position.x
        velocity.x = signf(dx) * 32.0 if absf(dx) > 430.0 else 0.0
        if shoot_timer <= 0.0:
            shoot_timer = 1.45
            _shoot()
        if ground_timer <= 0.0:
            ground_timer = 4.0
            _ground_attack()
    move_and_slide()

func activate_rune() -> void:
    if not can_receive_combat_effects() or not shielded:
        return
    rune_count += 1
    if rune_count >= 3:
        _drop_shield()

func _drop_shield() -> void:
    if shield_window_running or not can_receive_combat_effects():
        return
    phase_generation += 1
    var token := phase_generation
    shielded = false
    shield_window_running = true
    core.visible = true
    shield_changed.emit(false)
    await get_tree().create_timer(5.0).timeout
    if (
        token == phase_generation
        and is_inside_tree()
        and can_receive_combat_effects()
    ):
        shielded = true
        shield_window_running = false
        rune_count = 0
        core.visible = false
        shield_changed.emit(true)

func receive_kick(
    force: float,
    damage: int,
    direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if not can_receive_combat_effects() or shielded:
        return
    var dealt := damage + 1 if charged else damage
    health = maxi(health - dealt, 0)
    health_changed.emit(health, max_health)
    velocity.x = direction.x * force * 0.16
    AudioManager.play_sfx("boss_hit_sfx")
    if health <= 0 and not defeated_once:
        defeated_once = true
        world_active = false
        defeated.emit()
        queue_free()

func receive_weapon_hit(
    damage: int, direction: Vector2, weapon: String, _source: Node = null
) -> void:
    if not can_receive_combat_effects() or shielded:
        return
    var dealt := maxi(damage, 1)
    health = maxi(health - dealt, 0)
    health_changed.emit(health, max_health)
    velocity.x = direction.normalized().x * (170.0 if weapon == "sword" else 95.0)
    AudioManager.play_sfx("boss_hit_sfx")
    if health <= 0 and not defeated_once:
        defeated_once = true
        world_active = false
        defeated.emit()
        queue_free()

func receive_projectile(_reflected: bool, _source: Node = null) -> void:
    return

func _shoot() -> void:
    if target == null or not world_active:
        return
    var token := phase_generation
    modulate = Color("ffc66e")
    await get_tree().create_timer(0.32).timeout
    modulate = Color.WHITE
    if token != phase_generation or not world_active or target == null:
        return
    var scene := load(
        "res://scenes/enemies/reflectable_projectile.tscn"
    ) as PackedScene
    var shot := scene.instantiate() as ReflectableProjectile
    get_parent().add_child(shot)
    shot.global_position = global_position + Vector2(0, -100)
    shot.launch(
        shot.global_position.direction_to(
            target.global_position + Vector2(0, -40)
        ) * 410.0,
        self,
    )

func _ground_attack() -> void:
    if target == null or not world_active:
        return
    var token := phase_generation
    var warning := Polygon2D.new()
    warning.polygon = PackedVector2Array([
        Vector2(-120, -8),
        Vector2(120, -8),
        Vector2(120, 8),
        Vector2(-120, 8),
    ])
    warning.color = Color(1, 0.2, 0.1, 0.55)
    get_parent().add_child(warning)
    warning.global_position = target.global_position + Vector2(0, 10)
    await get_tree().create_timer(0.65).timeout
    if (
        token == phase_generation
        and world_active
        and is_instance_valid(target)
        and target.global_position.distance_to(warning.global_position) < 130.0
    ):
        target.take_damage(1, Vector2(0, -260))
    warning.queue_free()

func reset_state() -> void:
    phase_generation += 1
    health = max_health
    shielded = true
    rune_count = 0
    shield_window_running = false
    defeated_once = false
    core.visible = false
    shoot_timer = 1.0
    ground_timer = 3.0
    world_active = false
    velocity = Vector2.ZERO
    health_changed.emit(health, max_health)
