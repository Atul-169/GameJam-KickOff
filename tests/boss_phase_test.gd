extends SceneTree

var failures: Array[String] = []
var container: Node2D
var phase_emissions: int = 0
var defeat_emissions: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	container = Node2D.new()
	get_root().add_child(container)
	var packed := load("res://scenes/enemies/keeper.tscn") as PackedScene
	if packed == null:
		failures.append("Keeper scene could not be loaded")
		_finish()
		return
	var keeper := packed.instantiate() as KeeperBoss
	if keeper == null:
		failures.append("Keeper scene did not instantiate as KeeperBoss")
		_finish()
		return
	container.add_child(keeper)
	_test_phase_guard(keeper)
	_test_positioned_trap()
	_test_final_charged_finish(keeper)
	container.queue_free()
	_finish()

func _test_phase_guard(keeper: KeeperBoss) -> void:
	phase_emissions = 0
	if not keeper.phase_changed.is_connected(_on_phase_changed):
		keeper.phase_changed.connect(_on_phase_changed)
	keeper.set_phase(1)
	keeper.set_phase(1)
	keeper.set_phase(2)
	keeper.set_phase(2)
	if phase_emissions != 2:
		failures.append("Keeper repeated a phase transition")
	if keeper.phase_changed.is_connected(_on_phase_changed):
		keeper.phase_changed.disconnect(_on_phase_changed)

func _on_phase_changed(_phase: int) -> void:
	phase_emissions += 1

func _test_positioned_trap() -> void:
	var trap := KeeperTrap.new()
	container.add_child(trap)
	trap.global_position = Vector2.ZERO
	if trap.try_break(Vector2(500, 0), Vector2.ZERO, true, 1):
		failures.append("Distant Keeper incorrectly broke a trap")
	if trap.try_break(Vector2.ZERO, Vector2(500, 0), true, 2):
		failures.append("Distant copied attack incorrectly broke a trap")
	if trap.try_break(Vector2.ZERO, Vector2.ZERO, false, 3):
		failures.append("Normal copied attack incorrectly broke charged-only trap")
	if not trap.try_break(Vector2.ZERO, Vector2.ZERO, true, 4):
		failures.append("Valid positioned charged copy did not break a trap")
	if trap.try_break(Vector2.ZERO, Vector2.ZERO, true, 5):
		failures.append("Already-broken trap counted twice")

func _test_final_charged_finish(keeper: KeeperBoss) -> void:
	defeat_emissions = 0
	if not keeper.defeated.is_connected(_on_keeper_defeated):
		keeper.defeated.connect(_on_keeper_defeated)
	keeper.set_phase(3)
	keeper.begin_final_exposure()
	keeper.receive_core_kick(500.0, 1, Vector2.RIGHT, false, container)
	if defeat_emissions != 0:
		failures.append("Normal kick finished the final Keeper core")
	keeper.receive_core_kick(900.0, 2, Vector2.RIGHT, true, container)
	keeper.receive_core_kick(900.0, 2, Vector2.RIGHT, true, container)
	if defeat_emissions != 1:
		failures.append("Charged final hit did not emit exactly one defeat")
	if keeper.defeated.is_connected(_on_keeper_defeated):
		keeper.defeated.disconnect(_on_keeper_defeated)

func _on_keeper_defeated() -> void:
	defeat_emissions += 1

func _finish() -> void:
	if failures.is_empty():
		print("boss_phase_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("boss_phase_test: FAIL (%d)" % failures.size())
	quit(1)
