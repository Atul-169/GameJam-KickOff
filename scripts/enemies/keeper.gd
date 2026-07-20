class_name KeeperBoss
extends CharacterBody2D

signal defeated
signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)
signal copied_attack_hit_trap(trap: Node)

const BASE_MAX_HEALTH := 18
const FINAL_SEGMENT_HEALTH := 3

var target: ArinController
var phase := 0
var health := BASE_MAX_HEALTH
var max_health := BASE_MAX_HEALTH
var shielded := true
var world_active := false
var shot_timer := 1.0
var copied_pending := false
var final_exposed := false
var defeat_emitted := false
var copied_attack_id := 0
var action_generation := 0
var normal_finish_hint_shown := false

@onready var core: Node2D = $Core
@onready var core_hitbox: BossCoreHitbox = $CoreHitbox
var health_bar: EnemyHealthBar

func _ready() -> void:
    add_to_group("enemy")
    add_to_group("freezable")
    add_to_group("resettable")
    $VisualRoot.add_child(
        AssetRegistry.make_visual(
            "keeper", Vector2(150, 205), Color("22162d"), "KEEPER"
        )
    )
    core.add_child(
        AssetRegistry.make_visual(
            "boss_core", Vector2(50, 70), Color("b34cff"), "CORE"
        )
    )
    core.visible = false
    core_hitbox.boss = self
    core_hitbox.set_enabled(false)
    health_bar = EnemyHealthBar.new()
    health_bar.position = Vector2(0, -235)
    health_bar.bar_size = Vector2(174, 16)
    add_child(health_bar)
    health_bar.setup("KEEPER", max_health, health)
    health_changed.connect(health_bar.update_health)

func _exit_tree() -> void:
    action_generation += 1
    _disconnect_kick_listener()

func set_target(value: ArinController) -> void:
    target = value

func set_world_active(value: bool) -> void:
    world_active = value

func set_phase(value: int) -> void:
    if phase == value:
        return
    action_generation += 1
    copied_pending = false
    _disconnect_kick_listener()
    phase = value
    phase_changed.emit(phase)
    EventBus.boss_phase_changed.emit(phase)
    if phase == 2 and not EventBus.player_kicked.is_connected(_observe_kick):
        EventBus.player_kicked.connect(_observe_kick)

func _disconnect_kick_listener() -> void:
    if EventBus.player_kicked.is_connected(_observe_kick):
        EventBus.player_kicked.disconnect(_observe_kick)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += 1100.0 * delta
    if world_active and target != null and is_instance_valid(target):
        if phase == 1:
            shot_timer -= delta
            if shot_timer <= 0.0:
                shot_timer = 1.25
                _shoot()
        elif phase == 2:
            var horizontal_distance := target.global_position.x - global_position.x
            velocity.x = (
                signf(horizontal_distance) * 72.0
                if absf(horizontal_distance) > 105.0
                else 0.0
            )
        elif phase == 3 and not final_exposed:
            velocity.x = (
                signf(target.global_position.x - global_position.x) * 42.0
            )
            shot_timer -= delta
            if shot_timer <= 0.0:
                shot_timer = 2.1
                _shoot()
    else:
        velocity.x = 0.0
    move_and_slide()

func expose_core(value: bool) -> void:
    if final_exposed:
        return
    shielded = not value
    core.visible = value
    core_hitbox.set_enabled(value)

func begin_final_exposure() -> void:
    if final_exposed or defeat_emitted:
        return
    final_exposed = true
    world_active = false
    shielded = false
    velocity = Vector2.ZERO
    max_health = FINAL_SEGMENT_HEALTH
    health = FINAL_SEGMENT_HEALTH
    core.visible = true
    core_hitbox.set_enabled(true)
    health_changed.emit(health, max_health)

func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    _charged: bool,
    _source: Node
) -> void:
    return

func receive_weapon_hit(
    damage: int, _direction: Vector2, weapon: String, _source: Node = null
) -> void:
    if defeat_emitted or shielded:
        return
    if phase == 1 or (phase == 3 and final_exposed):
        health = maxi(health - maxi(damage, 1), 0)
        health_changed.emit(health, max_health)
        AudioManager.play_sfx("boss_hit_sfx")
        if health <= 0:
            _emit_defeated_once()

func receive_core_kick(
    _force: float,
    damage: int,
    _direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if defeat_emitted:
        return
    if phase == 1:
        if shielded:
            return
        var dealt := damage + (1 if charged else 0)
        health = maxi(health - dealt, 0)
        health_changed.emit(health, max_health)
        AudioManager.play_sfx("boss_hit_sfx")
        return
    if phase == 3 and final_exposed:
        if not charged:
            if not normal_finish_hint_shown:
                normal_finish_hint_shown = true
                EventBus.dialogue_requested.emit(
                    "ARIN", "The exposed core needs a charged kick!", 1.6
                )
            return
        health = 0
        health_changed.emit(health, max_health)
        AudioManager.play_sfx("boss_hit_sfx")
        _emit_defeated_once()

func _emit_defeated_once() -> void:
    if defeat_emitted:
        return
    defeat_emitted = true
    world_active = false
    core_hitbox.set_enabled(false)
    _disconnect_kick_listener()
    defeated.emit()

func heal_percent(value: float) -> void:
    if defeat_emitted or final_exposed:
        return
    health = mini(
        max_health,
        health + ceili(float(max_health) * clampf(value, 0.0, 1.0)),
    )
    health_changed.emit(health, max_health)

func _shoot() -> void:
    if target == null or not is_instance_valid(target):
        return
    action_generation += 1
    var token := action_generation
    modulate = Color("c96cff")
    await get_tree().create_timer(0.35).timeout
    if (
        token != action_generation
        or not is_inside_tree()
        or not world_active
        or target == null
        or not is_instance_valid(target)
    ):
        modulate = Color.WHITE
        return
    modulate = Color.WHITE
    var scene := load(
        "res://scenes/enemies/reflectable_projectile.tscn"
    ) as PackedScene
    if scene == null:
        return
    var shot := scene.instantiate() as ReflectableProjectile
    get_parent().add_child(shot)
    shot.global_position = global_position + Vector2(0, -110)
    shot.launch(
        shot.global_position.direction_to(
            target.global_position + Vector2(0, -45)
        ) * 430.0,
        self,
    )

func _observe_kick(
    charged: bool, _origin: Vector2, direction: Vector2
) -> void:
    if phase != 2 or copied_pending or not world_active:
        return
    copied_pending = true
    action_generation += 1
    var token := action_generation
    modulate = Color("df9cff")
    await get_tree().create_timer(0.78 if charged else 0.64).timeout
    if (
        token != action_generation
        or not is_inside_tree()
        or phase != 2
        or not world_active
    ):
        copied_pending = false
        modulate = Color.WHITE
        return
    modulate = Color.WHITE
    _copied_shockwave(charged, direction.normalized())
    copied_pending = false

func _copied_shockwave(charged: bool, direction: Vector2) -> void:
    copied_attack_id += 1
    var attack_id := copied_attack_id
    var length := 430.0 if charged else 250.0
    var wave := Area2D.new()
    wave.add_to_group("temporary")
    wave.collision_layer = CollisionLayers.ENEMY_ATTACK
    wave.collision_mask = (
        CollisionLayers.PLAYER | CollisionLayers.TRIGGER
    )
    var shape_node := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(length, 100 if charged else 70)
    shape_node.shape = rectangle
    wave.add_child(shape_node)
    get_parent().add_child(wave)
    wave.global_position = (
        global_position
        + direction * length * 0.45
        + Vector2(0, -20)
    )
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-length * 0.5, -20),
        Vector2(length * 0.5, -8),
        Vector2(length * 0.5, 8),
        Vector2(-length * 0.5, 20),
    ])
    visual.color = Color(0.68, 0.25, 0.92, 0.55)
    wave.add_child(visual)
    await get_tree().physics_frame
    if not is_instance_valid(wave):
        return
    for body: Node in wave.get_overlapping_bodies():
        if body is ArinController:
            body.take_damage(1, direction * 300.0)
    var selected_trap: KeeperTrap
    var closest_distance := INF
    for area: Area2D in wave.get_overlapping_areas():
        if area is KeeperTrap:
            var trap := area as KeeperTrap
            if trap.can_break(
                global_position,
                wave.global_position,
                charged,
                attack_id,
            ):
                var distance := global_position.distance_to(
                    trap.global_position
                )
                if distance < closest_distance:
                    closest_distance = distance
                    selected_trap = trap
    if selected_trap != null and selected_trap.try_break(
        global_position,
        wave.global_position,
        charged,
        attack_id,
    ):
        copied_attack_hit_trap.emit(selected_trap)
    await get_tree().create_timer(0.16).timeout
    if is_instance_valid(wave):
        wave.queue_free()

func reset_state() -> void:
    action_generation += 1
    _disconnect_kick_listener()
    health = BASE_MAX_HEALTH
    max_health = BASE_MAX_HEALTH
    phase = 0
    shielded = true
    world_active = false
    shot_timer = 1.0
    copied_pending = false
    final_exposed = false
    defeat_emitted = false
    copied_attack_id = 0
    normal_finish_hint_shown = false
    core.visible = false
    core_hitbox.set_enabled(false)
    modulate = Color.WHITE
    velocity = Vector2.ZERO
    health_changed.emit(health, max_health)
