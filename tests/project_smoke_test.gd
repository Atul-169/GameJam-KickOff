extends SceneTree

const REQUIRED_SCENES: Array[String] = [
    "res://scenes/core/main.tscn",
    "res://scenes/characters/arin.tscn",
    "res://scenes/characters/niko.tscn",
    "res://scenes/levels/prologue_forest.tscn",
    "res://scenes/levels/level_01_gear_hall.tscn",
    "res://scenes/levels/level_02_echo_archive.tscn",
    "res://scenes/levels/level_03_guardian_court.tscn",
    "res://scenes/levels/level_04_sealed_heart.tscn",
    "res://scenes/enemies/stone_guardian.tscn",
    "res://scenes/enemies/arc_guardian.tscn",
    "res://scenes/enemies/echo_shade.tscn",
    "res://scenes/enemies/echo_warden.tscn",
    "res://scenes/enemies/warden_echo_projectile.tscn",
    "res://scenes/environment/echo_breakable_wall.tscn",
    "res://scenes/interactables/echo_timed_gate.tscn",
    "res://scenes/interactables/echo_seal_lock.tscn",
    "res://scenes/interactables/resonance_strike.tscn",
    "res://scenes/hazards/echo_shockwave.tscn",
    "res://scenes/enemies/shadow_hunter.tscn",
    "res://scenes/enemies/gatekeeper.tscn",
    "res://scenes/enemies/keeper.tscn",
    "res://scenes/ui/main_menu.tscn",
    "res://scenes/ui/game_hud.tscn",
    "res://scenes/ui/pause_menu.tscn",
    "res://scenes/ui/settings_menu.tscn",
    "res://scenes/ui/results_screen.tscn",
    "res://scenes/ui/fail_screen.tscn",
    "res://scenes/ui/ending_screen.tscn",
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for path in REQUIRED_SCENES:
        var packed := load(path) as PackedScene
        if packed == null:
            failures.append("Unable to load: " + path)
            continue
        var instance := packed.instantiate()
        if instance == null:
            failures.append("Unable to instantiate: " + path)
            continue
        instance.free()
    _finish("project_smoke_test")

func _finish(test_name: String) -> void:
    if failures.is_empty():
        print(test_name + ": PASS")
        quit(0)
        return
    for failure in failures:
        push_error(failure)
    print(test_name + ": FAIL (%d)" % failures.size())
    quit(1)
