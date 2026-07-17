extends SceneTree

var failures: Array[String] = []
var container: Node2D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    container = Node2D.new()
    get_root().add_child(container)
    await _test_enemy_guards()
    await _test_environment_guards()
    await _test_projectile_guard()
    _test_wave_guards()
    container.queue_free()
    await process_frame
    _finish()

func _test_enemy_guards() -> void:
    var packed := load(
        "res://scenes/enemies/stone_guardian.tscn"
    ) as PackedScene
    var enemy := packed.instantiate() as StoneGuardian
    container.add_child(enemy)
    await process_frame
    var initial_health := enemy.health.current_health
    enemy.set_world_active(false)
    enemy.receive_kick(900.0, 2, Vector2.RIGHT, true, container)
    enemy.receive_projectile(true, container)
    enemy.receive_explosion(2, Vector2.LEFT)
    enemy.receive_heavy_collision(Vector2.LEFT)
    enemy.stun(0.1)
    if enemy.health.current_health != initial_health:
        failures.append("Frozen enemy accepted combat damage")
    if enemy.knockback != Vector2.ZERO or enemy.stunned:
        failures.append("Frozen enemy accepted knockback or stun")
    enemy.set_world_active(true)
    enemy.receive_kick(500.0, 1, Vector2.RIGHT, false, container)
    if enemy.health.current_health >= initial_health:
        failures.append("Active enemy rejected valid kick damage")

func _test_environment_guards() -> void:
    var jar_scene := load(
        "res://scenes/interactables/rune_jar.tscn"
    ) as PackedScene
    var jar := jar_scene.instantiate() as RuneJar
    container.add_child(jar)
    await process_frame
    jar.set_world_active(false)
    jar.receive_kick(700.0, 1, Vector2.RIGHT, true, container)
    jar.explode()
    if jar.armed or jar.exploded_once or jar.velocity_external != Vector2.ZERO:
        failures.append("Frozen Rune Jar accepted kick or explosion state")
    jar.set_world_active(true)
    jar.receive_kick(700.0, 1, Vector2.RIGHT, true, container)
    if not jar.armed:
        failures.append("Active Rune Jar rejected a valid kick")

    var pillar_scene := load(
        "res://scenes/environment/breakable_pillar.tscn"
    ) as PackedScene
    var pillar := pillar_scene.instantiate() as BreakablePillar
    container.add_child(pillar)
    await process_frame
    pillar.set_world_active(false)
    pillar.receive_projectile(true, container)
    pillar.receive_explosion(2, Vector2.ZERO)
    pillar.receive_heavy_impact()
    if pillar.broken_once:
        failures.append("Frozen pillar accepted combat damage")
    pillar.set_world_active(true)
    pillar.receive_projectile(true, container)
    if not pillar.broken_once:
        failures.append("Active pillar rejected a reflected projectile")

func _test_projectile_guard() -> void:
    var projectile_scene := load(
        "res://scenes/enemies/reflectable_projectile.tscn"
    ) as PackedScene
    var projectile := projectile_scene.instantiate() as ReflectableProjectile
    container.add_child(projectile)
    await process_frame
    projectile.configure_suspended(Vector2(300, 0), true)
    projectile.receive_kick(500.0, 1, Vector2.RIGHT, false, container)
    if projectile.active or projectile.reflected:
        failures.append("Suspended projectile moved or reflected while frozen")
    if projectile.collision_layer != 0 or projectile.monitoring:
        failures.append("Suspended projectile remained harmful while frozen")
    projectile.set_world_active(true)
    if not projectile.active or not projectile.reflectable:
        failures.append("Suspended projectile did not activate after Kickoff")

func _test_wave_guards() -> void:
    var court := GuardianCourt.new()
    court.state_controller = ChallengeStateController.new()
    court.state_controller.state = GameState.GameMode.FROZEN
    var dummy := EnemyBase.new()
    court.alive.append(dummy)
    court.wave = 1
    if court.can_process_enemy_defeat(dummy):
        failures.append("Frozen Level 3 accepts enemy defeat progression")
    if court.can_start_arena() == false:
        failures.append("Frozen Level 3 cannot start from the Bell")
    court.arena_started = true
    if court.can_start_arena():
        failures.append("Bell can reactivate an already-started arena")
    court.state_controller.state = GameState.GameMode.ACTIVE
    if not court.can_process_enemy_defeat(dummy):
        failures.append("Active Level 3 rejects valid enemy defeat progression")
    dummy.free()
    court.state_controller.free()
    court.free()

func _finish() -> void:
    if failures.is_empty():
        print("frozen_combat_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("frozen_combat_test: FAIL (%d)" % failures.size())
    quit(1)
