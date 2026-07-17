class_name EchoWarden
extends CharacterBody2D

signal projectile_requested(origin: Vector2, direction: Vector2)
signal shockwave_requested(origin: Vector2)
signal core_health_changed(current: int, maximum: int)
signal core_exposed_changed(active: bool)
signal awakening_changed(stage: int)
signal defeated


enum Awakening { DORMANT, HEARING, VISION, VOICE, DEFEATED }
enum Action {
    IDLE,
    CHARGE_TELEGRAPH,
    CHARGING,
    STUNNED,
    SCREAM_TELEGRAPH,
    CORE_EXPOSED,
}

const GRAVITY := 1200.0
const CORE_MAX_HEALTH := 3

@export var move_speed := 115.0
@export var charge_speed := 610.0
@export var charge_duration := 1.35
@export var charge_warning := 0.48
@export var projectile_interval := 3.1
@export var scream_interval := 4.8
@export var core_exposure_duration := 2.65

var target: ArinController
var world_active := false
var awakening := Awakening.DORMANT
var action := Action.IDLE
var action_timer := 0.0
var charge_direction := 1.0
var charge_hit_player := false
var last_sound_position := Vector2.ZERO
var sound_memory := 0.0
var sound_scan_timer := 0.0
var hearing_cooldown := 0.0
var projectile_timer := 1.2
var scream_timer := 2.0
var enrage_timer := 0.0
var core_health := CORE_MAX_HEALTH
var core_hit_this_window := false
var defeat_emitted := false
var facing := 1.0
var arena_bounds := Rect2(900, 420, 5000, 480)
var core_pulse_tween: Tween

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot
@onready var core_area: EchoCoreHitbox = $CoreArea
@onready var core_visual: Node2D = $CoreVisual
@onready var vision_cone: Polygon2D = $VisionCone
@onready var phase_label: Label = $PhaseLabel

func _ready() -> void:
    collision_layer = CollisionLayers.ENEMY
    collision_mask = (
        CollisionLayers.WORLD
        | CollisionLayers.PLAYER
        | CollisionLayers.KICKABLE
        | CollisionLayers.PROJECTILE
    )
    visual_root.add_child(
        AssetRegistry.make_visual(
            "echo_warden",
            Vector2(126, 170),
            Color("697387"),
            "WARDEN",
        )
    )
    var core_texture := AssetRegistry.load_texture("boss_core")
    if core_texture != null:
        var sprite := Sprite2D.new()
        sprite.texture = core_texture
        sprite.scale = Vector2(0.42, 0.42)
        core_visual.add_child(sprite)
    else:
        var disc := Polygon2D.new()
        var points := PackedVector2Array()
        for index in 24:
            points.append(Vector2.from_angle(float(index) / 24.0 * TAU) * 30.0)
        disc.polygon = points
        disc.color = Color("76efff")
        core_visual.add_child(disc)
    core_area.warden = self
    core_visual.visible = false
    _set_core_exposed(false)
    vision_cone.visible = false
    phase_label.text = "DORMANT"
    add_to_group("resettable")
    add_to_group("echo_warden")
    if not EventBus.player_kicked.is_connected(_on_player_kicked):
        EventBus.player_kicked.connect(_on_player_kicked)

func _exit_tree() -> void:
    if EventBus.player_kicked.is_connected(_on_player_kicked):
        EventBus.player_kicked.disconnect(_on_player_kicked)

func set_target(value: ArinController) -> void:
    target = value

func configure_arena(bounds: Rect2) -> void:
    arena_bounds = bounds

func set_world_active(value: bool) -> void:
    world_active = value and awakening != Awakening.DEFEATED
    if not world_active:
        velocity = Vector2.ZERO
        if awakening != Awakening.DEFEATED:
            action = Action.IDLE
            action_timer = 0.0
            _set_core_exposed(false)

func awaken_hearing() -> void:
    if awakening >= Awakening.HEARING:
        return
    awakening = Awakening.HEARING
    phase_label.text = "HEARING"
    visual_root.modulate = Color("9aa5b8")
    hearing_cooldown = 0.5
    awakening_changed.emit(awakening)

func awaken_vision() -> void:
    if awakening >= Awakening.VISION:
        return
    awakening = Awakening.VISION
    phase_label.text = "VISION"
    vision_cone.visible = true
    projectile_timer = 1.0
    awakening_changed.emit(awakening)

func awaken_voice() -> void:
    if awakening >= Awakening.VOICE:
        return
    awakening = Awakening.VOICE
    phase_label.text = "FULLY AWAKE"
    scream_timer = 1.1
    core_health_changed.emit(core_health, CORE_MAX_HEALTH)
    awakening_changed.emit(awakening)

func enrage(duration: float) -> void:
    enrage_timer = maxf(enrage_timer, duration)
    modulate = Color("ff8fa3")

func notify_sound(position_value: Vector2, intensity: float = 1.0) -> void:
    if not world_active or awakening < Awakening.HEARING:
        return
    last_sound_position = position_value
    sound_memory = maxf(sound_memory, 0.7 + intensity * 0.55)

func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if not world_active or awakening == Awakening.DORMANT:
        return
    if action in [Action.CHARGE_TELEGRAPH, Action.CHARGING]:
        _enter_stun(0.55 if charged else 0.36)
        AudioManager.play_sfx("boss_hit_sfx")

func receive_projectile(reflected: bool, _source: Node = null) -> void:
    if not world_active or not reflected or awakening < Awakening.VISION:
        return
    if action != Action.CORE_EXPOSED:
        _enter_stun(0.30)

func receive_resonance_strike(_strike: Node) -> void:
    return

func receive_core_strike(strike: Node) -> void:
    if (
        not world_active
        or awakening != Awakening.VOICE
        or action != Action.CORE_EXPOSED
        or core_hit_this_window
        or strike == null
        or not strike.has_method("is_resonance_strike")
        or not bool(strike.call("is_resonance_strike"))
    ):
        return
    core_hit_this_window = true
    if strike.has_method("consume"):
        strike.call("consume")
    core_health = maxi(core_health - 1, 0)
    core_health_changed.emit(core_health, CORE_MAX_HEALTH)
    AudioManager.play_sfx("boss_hit_sfx")
    _impact_feedback()
    if core_health <= 0:
        _defeat()
        return
    _set_core_exposed(false)
    _enter_stun(0.65)
    scream_timer = 1.8

func reset_state() -> void:
    defeat_emitted = false
    world_active = false
    awakening = Awakening.DORMANT
    action = Action.IDLE
    action_timer = 0.0
    velocity = Vector2.ZERO
    last_sound_position = Vector2.ZERO
    sound_memory = 0.0
    sound_scan_timer = 0.0
    hearing_cooldown = 0.0
    projectile_timer = 1.2
    scream_timer = 2.0
    enrage_timer = 0.0
    core_health = CORE_MAX_HEALTH
    core_hit_this_window = false
    collision.set_deferred("disabled", false)
    collision_layer = CollisionLayers.ENEMY
    collision_mask = (
        CollisionLayers.WORLD
        | CollisionLayers.PLAYER
        | CollisionLayers.KICKABLE
        | CollisionLayers.PROJECTILE
    )
    modulate = Color.WHITE
    visual_root.modulate = Color.WHITE
    vision_cone.visible = false
    phase_label.text = "DORMANT"
    _set_core_exposed(false)

func _physics_process(delta: float) -> void:
    if not world_active or awakening in [Awakening.DORMANT, Awakening.DEFEATED]:
        velocity = Vector2.ZERO
        return
    _update_timers(delta)
    _listen_for_movement(delta)
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    match action:
        Action.IDLE:
            _think_idle()
        Action.CHARGE_TELEGRAPH:
            velocity.x = 0.0
            if action_timer <= 0.0:
                action = Action.CHARGING
                action_timer = charge_duration
                charge_hit_player = false
        Action.CHARGING:
            velocity.x = charge_direction * _current_charge_speed()
            if action_timer <= 0.0:
                _enter_stun(0.45)
        Action.STUNNED:
            velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
            if action_timer <= 0.0:
                action = Action.IDLE
                modulate = Color.WHITE
        Action.SCREAM_TELEGRAPH:
            velocity.x = 0.0
            if action_timer <= 0.0:
                shockwave_requested.emit(global_position + Vector2(0, 70))
                _set_core_exposed(true, core_exposure_duration)
        Action.CORE_EXPOSED:
            velocity.x = 0.0
            if action_timer <= 0.0:
                _set_core_exposed(false)
                action = Action.IDLE
                scream_timer = 1.6
    move_and_slide()
    _handle_collisions()
    global_position.x = clampf(
        global_position.x,
        arena_bounds.position.x,
        arena_bounds.end.x,
    )
    if global_position.y > arena_bounds.end.y + 250.0:
        global_position = Vector2(
            clampf(global_position.x, arena_bounds.position.x, arena_bounds.end.x),
            arena_bounds.end.y - 80.0,
        )
        velocity = Vector2.ZERO
    _update_visual_direction()

func _update_timers(delta: float) -> void:
    action_timer = maxf(action_timer - delta, 0.0)
    hearing_cooldown = maxf(hearing_cooldown - delta, 0.0)
    projectile_timer = maxf(projectile_timer - delta, 0.0)
    scream_timer = maxf(scream_timer - delta, 0.0)
    sound_memory = maxf(sound_memory - delta, 0.0)
    enrage_timer = maxf(enrage_timer - delta, 0.0)
    if enrage_timer <= 0.0 and action not in [Action.SCREAM_TELEGRAPH]:
        modulate = Color.WHITE

func _listen_for_movement(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        return
    sound_scan_timer = maxf(sound_scan_timer - delta, 0.0)
    var noisy := absf(target.velocity.x) > 55.0 or not target.is_on_floor()
    if noisy and sound_scan_timer <= 0.0:
        notify_sound(target.global_position, 0.45)
        sound_scan_timer = 0.24

func _think_idle() -> void:
    if target == null or not is_instance_valid(target):
        velocity.x = 0.0
        return
    if awakening == Awakening.VOICE and scream_timer <= 0.0:
        action = Action.SCREAM_TELEGRAPH
        action_timer = 0.75
        modulate = Color("c596ff")
        phase_label.text = "SCREAM CHARGING"
        return
    if sound_memory > 0.0 and hearing_cooldown <= 0.0:
        _begin_charge(last_sound_position)
        return
    if awakening >= Awakening.VISION:
        facing = signf(target.global_position.x - global_position.x)
        if absf(target.global_position.x - global_position.x) > 210.0:
            velocity.x = facing * move_speed * _enrage_multiplier()
        else:
            velocity.x = 0.0
        if projectile_timer <= 0.0:
            projectile_timer = projectile_interval / _enrage_multiplier()
            var origin := global_position + Vector2(facing * 72.0, -58.0)
            projectile_requested.emit(
                origin,
                origin.direction_to(target.global_position + Vector2(0, -35)),
            )
    else:
        velocity.x = 0.0

func _begin_charge(sound_position: Vector2) -> void:
    charge_direction = signf(sound_position.x - global_position.x)
    if is_zero_approx(charge_direction):
        charge_direction = facing
    facing = charge_direction
    action = Action.CHARGE_TELEGRAPH
    action_timer = charge_warning
    hearing_cooldown = 1.25
    sound_memory = 0.0
    modulate = Color("ffd27d")
    phase_label.text = "CHARGE"

func _enter_stun(duration: float) -> void:
    action = Action.STUNNED
    action_timer = maxf(duration, 0.1)
    velocity.x = 0.0
    modulate = Color("a6f4ff")
    phase_label.text = "STUNNED"

func _set_core_exposed(active: bool, duration: float = 0.0) -> void:
    if core_pulse_tween != null and core_pulse_tween.is_valid():
        core_pulse_tween.kill()
    core_pulse_tween = null
    core_visual.scale = Vector2.ONE
    core_visual.visible = active
    core_area.set_deferred("monitoring", active)
    core_area.set_deferred("monitorable", active)
    core_area.set_deferred(
        "collision_layer", CollisionLayers.ENEMY if active else 0
    )
    core_area.set_deferred(
        "collision_mask", CollisionLayers.PLAYER_KICK if active else 0
    )
    core_hit_this_window = false
    core_exposed_changed.emit(active)
    if active:
        action = Action.CORE_EXPOSED
        action_timer = maxf(duration, 0.1)
        phase_label.text = "CORE EXPOSED"
        core_pulse_tween = create_tween().set_loops()
        core_pulse_tween.tween_property(
            core_visual, "scale", Vector2(1.18, 1.18), 0.22
        )
        core_pulse_tween.tween_property(
            core_visual, "scale", Vector2.ONE, 0.22
        )
    elif awakening == Awakening.VOICE:
        phase_label.text = "FULLY AWAKE"

func _handle_collisions() -> void:
    if action != Action.CHARGING:
        return
    for index in get_slide_collision_count():
        var collision_data := get_slide_collision(index)
        var collider := collision_data.get_collider()
        if collider == null:
            continue
        if collider is ArinController and not charge_hit_player:
            charge_hit_player = true
            collider.take_damage(
                1,
                Vector2(charge_direction * 300.0, -110.0),
            )
        if collider.has_method("receive_warden_charge"):
            var broken := bool(
                collider.call(
                    "receive_warden_charge",
                    _current_charge_speed(),
                    global_position,
                )
            )
            if broken:
                _enter_stun(1.15)
                if target != null and is_instance_valid(target):
                    target._camera_shake(8.0)
                return
        if collider is StaticBody2D:
            _enter_stun(0.55)
            return

func _on_player_kicked(
    _charged: bool, origin: Vector2, _direction: Vector2
) -> void:
    notify_sound(origin, 1.0)

func _current_charge_speed() -> float:
    return charge_speed * _enrage_multiplier()

func _enrage_multiplier() -> float:
    return 1.32 if enrage_timer > 0.0 else 1.0

func _update_visual_direction() -> void:
    if absf(velocity.x) > 8.0:
        facing = signf(velocity.x)
    visual_root.scale.x = absf(visual_root.scale.x) * facing
    core_visual.scale.x = absf(core_visual.scale.x) * facing
    vision_cone.scale.x = facing

func _impact_feedback() -> void:
    modulate = Color("e4ffff")
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.24)
    if target != null and is_instance_valid(target):
        target._camera_shake(7.0)

func _defeat() -> void:
    if defeat_emitted:
        return
    defeat_emitted = true
    awakening = Awakening.DEFEATED
    world_active = false
    action = Action.IDLE
    velocity = Vector2.ZERO
    collision.set_deferred("disabled", true)
    set_deferred("collision_layer", 0)
    set_deferred("collision_mask", 0)
    _set_core_exposed(false)
    phase_label.text = "SILENCED"
    defeated.emit()
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color(0.4, 0.9, 1.0, 0.25), 0.45)
    tween.tween_property(self, "modulate:a", 0.0, 0.45)
