class_name GuardianCourt
extends LevelManager

var bell: KickTrigger
var wave := 0
var alive: Array[EnemyBase] = []
var boss: GatekeeperBoss
var boss_runes: Array[ProjectileRune] = []
var suspended: ReflectableProjectile
var rune_jars: Array[RuneJar] = []
var pillars: Array[BreakablePillar] = []
var arena_gates: Array[StaticBody2D] = []
var arena_started := false
var wave_advancing := false
var gatekeeper_spawned := false
var boss_defeat_started := false
var wave_generation := 0

func _init() -> void:
    level_id = "level_03"
    level_title = "Court of Guardians"
    music_key = "guardian_combat_music"
    world_width = 4400.0
    checkpoint_position = Vector2(200, 790)

func build_level() -> void:
    _build_guardian_court_background()
    add_label(
        "COURT OF GUARDIANS",
        Vector2(1550, 130),
        42,
        Color("d8b27c"),
    )
    bell = spawn_scene(
        "res://scenes/interactables/kick_trigger.tscn", Vector2(720, 800)
    ) as KickTrigger
    bell.trigger_id = "kickoff_bell"
    bell.asset_key = "kickoff_bell"
    bell.caption = "KICKOFF BELL"
    bell.kicked.connect(_start_arena)

    _add_rune_jar(Vector2(1850, 820), false)
    _add_rune_jar(Vector2(2600, 820), false)
    _add_pillar(Vector2(1450, 890), 1)
    _add_pillar(Vector2(3050, 890), -1)
    arena_gates.append(_make_arena_gate(Vector2(430, 720)))
    arena_gates.append(_make_arena_gate(Vector2(4200, 720)))
    _set_gate_closed(false)

func post_ready() -> void:
    set_objective("Inspect the arena, then kick the bell.")
    _spawn_wave_one(false)
    suspended = spawn_scene(
        "res://scenes/enemies/reflectable_projectile.tscn",
        Vector2(1150, 560),
    ) as ReflectableProjectile
    suspended.configure_suspended(Vector2(300, 0), true)
    _set_combat_world_active(false)

func can_start_arena() -> bool:
    return (
        not arena_started
        and not completed
        and not failed
        and state_controller != null
        and state_controller.state == GameState.GameMode.FROZEN
    )

func is_arena_active() -> bool:
    return (
        arena_started
        and not completed
        and not failed
        and state_controller != null
        and state_controller.state == GameState.GameMode.ACTIVE
    )

func _start_arena(_charged: bool) -> void:
    if not can_start_arena():
        return
    arena_started = true
    start_kickoff()
    if not is_arena_active():
        return
    bell.collision_layer = 0
    bell.collision_mask = 0
    _set_gate_closed(true)
    _set_combat_world_active(true)
    AudioManager.play_music("guardian_combat_music")
    set_objective("Wave 1: Defeat the Stone Guardians.")

func _set_combat_world_active(active: bool) -> void:
    for enemy in alive:
        if is_instance_valid(enemy):
            enemy.set_world_active(active)
    for jar in rune_jars:
        if is_instance_valid(jar):
            jar.set_world_active(active)
    for pillar in pillars:
        if is_instance_valid(pillar):
            pillar.set_world_active(active)
    if suspended != null and is_instance_valid(suspended):
        suspended.set_world_active(active)
    if boss != null and is_instance_valid(boss):
        boss.set_world_active(active)

func _add_rune_jar(pos: Vector2, active: bool) -> RuneJar:
    var jar := spawn_scene(
        "res://scenes/interactables/rune_jar.tscn", pos
    ) as RuneJar
    jar.set_world_active(active)
    rune_jars.append(jar)
    return jar

func _add_pillar(pos: Vector2, direction: int) -> BreakablePillar:
    var pillar := spawn_scene(
        "res://scenes/environment/breakable_pillar.tscn", pos
    ) as BreakablePillar
    pillar.fall_direction = direction
    pillar.set_world_active(false)
    pillars.append(pillar)
    return pillar

func _make_arena_gate(pos: Vector2) -> StaticBody2D:
    var gate := StaticBody2D.new()
    gate.position = pos
    var shape_node := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(70, 360)
    shape_node.shape = shape
    gate.add_child(shape_node)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-35, -180),
        Vector2(35, -180),
        Vector2(35, 180),
        Vector2(-35, 180),
    ])
    visual.color = Color("8b6744")
    gate.add_child(visual)
    add_child(gate)
    return gate

func _set_gate_closed(closed: bool) -> void:
    for gate in arena_gates:
        if not is_instance_valid(gate):
            continue
        gate.collision_layer = CollisionLayers.WORLD if closed else 0
        gate.collision_mask = (
            CollisionLayers.PLAYER | CollisionLayers.ENEMY if closed else 0
        )
        gate.modulate.a = 1.0 if closed else 0.28

func _spawn_enemy(path: String, pos: Vector2) -> EnemyBase:
    var enemy := spawn_scene(path, pos) as EnemyBase
    enemy.set_target(player)
    enemy.set_world_active(is_arena_active())
    if not enemy.defeated.is_connected(_enemy_defeated):
        enemy.defeated.connect(_enemy_defeated)
    alive.append(enemy)
    return enemy

func _spawn_wave_one(start_active: bool) -> void:
    wave = 1
    _spawn_enemy(
        "res://scenes/enemies/stone_guardian.tscn", Vector2(1700, 800)
    )
    _spawn_enemy(
        "res://scenes/enemies/stone_guardian.tscn", Vector2(2250, 800)
    )
    if not start_active:
        for enemy in alive:
            enemy.set_world_active(false)

func can_process_enemy_defeat(enemy: EnemyBase) -> bool:
    return (
        is_arena_active()
        and is_instance_valid(enemy)
        and alive.has(enemy)
        and not wave_advancing
        and wave >= 1
        and wave <= 3
    )

func _enemy_defeated(enemy: EnemyBase) -> void:
    if not can_process_enemy_defeat(enemy):
        return
    alive.erase(enemy)
    if not alive.is_empty():
        return
    wave_advancing = true
    wave_generation += 1
    var token := wave_generation
    await get_tree().create_timer(0.35).timeout
    if (
        token != wave_generation
        or not is_arena_active()
        or not alive.is_empty()
    ):
        wave_advancing = false
        return
    wave_advancing = false
    _next_wave()

func _next_wave() -> void:
    if not is_arena_active():
        return
    if wave == 1:
        wave = 2
        set_objective("Wave 2: Stone and Arc Guardian.")
        _spawn_enemy(
            "res://scenes/enemies/stone_guardian.tscn",
            Vector2(1900, 800),
        )
        _spawn_enemy(
            "res://scenes/enemies/arc_guardian.tscn",
            Vector2(2900, 800),
        )
    elif wave == 2:
        wave = 3
        set_objective("Wave 3: Use Rune Jars and reflected shots.")
        _spawn_enemy(
            "res://scenes/enemies/arc_guardian.tscn",
            Vector2(1800, 800),
        )
        _spawn_enemy(
            "res://scenes/enemies/echo_shade.tscn",
            Vector2(2900, 800),
        )
        _add_rune_jar(Vector2(2200, 820), true)
        _add_rune_jar(Vector2(2600, 820), true)
    elif wave == 3:
        _spawn_gatekeeper()

func _spawn_gatekeeper() -> void:
    if not is_arena_active() or gatekeeper_spawned:
        return
    gatekeeper_spawned = true
    wave = 4
    set_objective(
        "Gatekeeper: Reflect projectiles into all three wall runes."
    )
    boss = spawn_scene(
        "res://scenes/enemies/gatekeeper.tscn", Vector2(3300, 790)
    ) as GatekeeperBoss
    boss.set_target(player)
    boss.set_world_active(true)
    boss.defeated.connect(_boss_defeated, CONNECT_ONE_SHOT)
    boss.health_changed.connect(
        func(current: int, maximum: int) -> void:
            hud.update_boss(current, maximum)
    )
    boss.shield_changed.connect(_shield_changed)
    hud.show_boss(
        "THE GATEKEEPER",
        boss.max_health,
        "SHIELDED — ACTIVATE 3 RUNES",
    )
    var rune_data: Array = [
        ["I", Vector2(3150, 470)],
        ["II", Vector2(3500, 350)],
        ["III", Vector2(3850, 470)],
    ]
    for data in rune_data:
        var rune := ProjectileRune.new()
        rune.rune_id = str(data[0])
        rune.position = data[1]
        add_child(rune)
        rune.activated.connect(_boss_rune)
        boss_runes.append(rune)

func _boss_rune(_rune: ProjectileRune) -> void:
    if is_arena_active() and boss != null and is_instance_valid(boss):
        boss.activate_rune()

func _shield_changed(enabled: bool) -> void:
    if not is_arena_active():
        return
    if enabled:
        for rune in boss_runes:
            rune.reset_state()
        hud.set_boss_phase("SHIELD RESTORED — ACTIVATE 3 RUNES")
    else:
        hud.set_boss_phase(
            "SHIELD DOWN FOR 5 SECONDS — USE CHARGED KICKS"
        )

func get_reflect_target() -> Vector2:
    for rune in boss_runes:
        if is_instance_valid(rune) and not rune.is_active:
            return rune.global_position
    for enemy in alive:
        if is_instance_valid(enemy):
            return enemy.global_position
    if boss != null and is_instance_valid(boss):
        return boss.global_position
    return super.get_reflect_target()

func _boss_defeated() -> void:
    if boss_defeat_started or not is_arena_active():
        return
    boss_defeat_started = true
    set_restart_blocked(true)
    _set_combat_world_active(false)
    hud.hide_boss()
    EventBus.boss_defeated.emit()
    var dialogue_completed := await hud.show_dialogue_sequence(
        [
            {
                "speaker": "ASTRA MAP",
                "text": "The final seal is near.",
                "duration": 2.0,
            },
            {
                "speaker": "ARIN",
                "text": "You said these trials were protecting Niko.",
                "duration": 2.4,
            },
            {
                "speaker": "ASTRA MAP",
                "text": "They protect what lies below.",
                "duration": 2.2,
            },
            {
                "speaker": "ARIN",
                "text": "That isn't the same answer.",
                "duration": 2.0,
            },
        ],
        true,
    )
    if dialogue_completed and is_inside_tree() and not completed:
        complete_level("force")

func fail_challenge(reason: String) -> void:
    if failed or completed:
        return
    wave_generation += 1
    wave_advancing = false
    arena_started = false
    _set_combat_world_active(false)
    _set_gate_closed(false)
    super.fail_challenge(reason)


func _build_guardian_court_background() -> void:
    var texture_paths: Array[String] = [
        "res://assets/environment/guardian_court/guardian_court_bg_01.png",
        "res://assets/environment/guardian_court/guardian_court_bg_02.png",
        "res://assets/environment/guardian_court/guardian_court_bg_03.png",
    ]

    for index in range(texture_paths.size()):
        var path: String = texture_paths[index]

        if not ResourceLoader.exists(path, "Texture2D"):
            push_warning("Missing Guardian Court background: " + path)
            continue

        var texture := ResourceLoader.load(
            path,
            "Texture2D"
        ) as Texture2D

        if texture == null:
            push_warning("Unable to load Guardian Court background: " + path)
            continue

        var sprite := Sprite2D.new()
        sprite.name = "GuardianCourtBackground%02d" % (index + 1)
        sprite.texture = texture
        sprite.centered = true
        sprite.position = Vector2(
            960.0 + 1920.0 * float(index),
            540.0
        )

        # LevelManager's opaque background uses z = -30.
        sprite.z_index = -29
        sprite.z_as_relative = false

        add_child(sprite)
