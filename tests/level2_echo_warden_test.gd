extends SceneTree

class FakeStrike:
    extends Node

    var consumed := false

    func is_resonance_strike() -> bool:
        return not consumed

    func consume() -> void:
        consumed = true

var failures: Array[String] = []
var container: Node

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    container = Node.new()
    get_root().add_child(container)
    await process_frame
    _test_warden_awakenings_and_core()
    _test_cracked_wall_guard()
    _test_echo_lock_guard()
    _test_level_design_contract()
    container.queue_free()
    await process_frame
    _finish()

func _test_warden_awakenings_and_core() -> void:
    var packed := load("res://scenes/enemies/echo_warden.tscn") as PackedScene
    var warden := packed.instantiate() as EchoWarden
    container.add_child(warden)
    await process_frame
    if warden.awakening != EchoWarden.Awakening.DORMANT:
        failures.append("Warden did not begin dormant")
    warden.set_world_active(true)
    warden.awaken_hearing()
    if warden.awakening != EchoWarden.Awakening.HEARING:
        failures.append("EAR did not enable hearing stage")
    warden.awaken_vision()
    if warden.awakening != EchoWarden.Awakening.VISION:
        failures.append("EYE did not enable vision stage")
    warden.awaken_voice()
    warden.set_world_active(true)
    if warden.awakening != EchoWarden.Awakening.VOICE:
        failures.append("MOUTH did not enable voice stage")
    var strike := FakeStrike.new()
    warden.receive_core_strike(strike)
    if warden.core_health != 3:
        failures.append("Closed core accepted a Resonance Strike")
    warden.action = EchoWarden.Action.CORE_EXPOSED
    warden.receive_core_strike(strike)
    if warden.core_health != 2 or not strike.consumed:
        failures.append("Exposed core rejected a valid Resonance Strike")
    var duplicate := FakeStrike.new()
    warden.receive_core_strike(duplicate)
    if warden.core_health != 2:
        failures.append("One exposure window counted more than one core hit")
    warden.queue_free()

func _test_cracked_wall_guard() -> void:
    var packed := load(
        "res://scenes/environment/echo_breakable_wall.tscn"
    ) as PackedScene
    var wall := packed.instantiate() as EchoBreakableWall
    container.add_child(wall)
    await process_frame
    if wall.receive_warden_charge(600.0, Vector2.ZERO):
        failures.append("Frozen cracked wall broke before Kickoff")
    wall.set_world_active(true)
    if not wall.receive_warden_charge(600.0, Vector2.ZERO):
        failures.append("Active Warden charge did not break cracked wall")
    if wall.receive_warden_charge(600.0, Vector2.ZERO):
        failures.append("Cracked wall broke more than once")
    wall.queue_free()

func _test_echo_lock_guard() -> void:
    var packed := load(
        "res://scenes/interactables/echo_seal_lock.tscn"
    ) as PackedScene
    var lock := packed.instantiate() as EchoSealLock
    container.add_child(lock)
    await process_frame
    var unlock_count := 0
    lock.unlocked.connect(func() -> void: unlock_count += 1)
    lock.receive_projectile(true)
    if unlock_count != 0:
        failures.append("Frozen Echo Lock accepted a projectile")
    lock.set_world_active(true)
    lock.receive_projectile(false)
    if unlock_count != 0:
        failures.append("Hostile projectile opened the Echo Lock")
    lock.receive_projectile(true)
    if unlock_count != 1:
        failures.append("Reflected projectile did not open the Echo Lock")
    lock.queue_free()

func _test_level_design_contract() -> void:
    var path := "res://scripts/levels/level_02_echo_archive.gd"
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        failures.append("Cannot read Level 2 script")
        return
    var text := file.get_as_text()
    if 'const ORDER: Array[String] = ["EAR", "EYE", "MOUTH"]' not in text:
        failures.append("Level 2 rune order is not EAR → EYE → MOUTH")
    if "Next rune:" in text or "EAR → EYE → MOUTH" in text:
        failures.append("HUD text reveals the full rune sequence")
    for required in [
        "awaken_hearing",
        "awaken_vision",
        "awaken_voice",
        "open_temporarily",
        "ResonanceStrike",
    ]:
        if required not in text:
            failures.append("Missing Level 2 mechanic: " + required)

func _finish() -> void:
    if failures.is_empty():
        print("level2_echo_warden_test: PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print("level2_echo_warden_test: FAIL (%d)" % failures.size())
    quit(1)
