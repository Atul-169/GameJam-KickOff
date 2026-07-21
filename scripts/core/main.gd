extends Node


var current_level: LevelManager
var current_level_index := -1

var overlay: Control
var pause_menu: PauseMenu
var fail_screen: FailScreen

var transition_serial := 0
var results_open := false
var transition_in_progress := false

var ui_layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	ui_layer = CanvasLayer.new()
	ui_layer.name = "MainUILayer"
	ui_layer.layer = 100
	add_child(ui_layer)

	if not EventBus.level_completed.is_connected(
		_on_level_completed
	):
		EventBus.level_completed.connect(
			_on_level_completed
		)

	if not EventBus.restart_requested.is_connected(
		_restart_current_level
	):
		EventBus.restart_requested.connect(
			_restart_current_level
		)

	if not EventBus.main_menu_requested.is_connected(
		show_main_menu
	):
		EventBus.main_menu_requested.connect(
			show_main_menu
		)

	if not EventBus.challenge_failed.is_connected(
		_on_challenge_failed
	):
		EventBus.challenge_failed.connect(
			_on_challenge_failed
		)

	show_main_menu()


func _exit_tree() -> void:
	if EventBus.level_completed.is_connected(
		_on_level_completed
	):
		EventBus.level_completed.disconnect(
			_on_level_completed
		)

	if EventBus.restart_requested.is_connected(
		_restart_current_level
	):
		EventBus.restart_requested.disconnect(
			_restart_current_level
		)

	if EventBus.main_menu_requested.is_connected(
		show_main_menu
	):
		EventBus.main_menu_requested.disconnect(
			show_main_menu
		)

	if EventBus.challenge_failed.is_connected(
		_on_challenge_failed
	):
		EventBus.challenge_failed.disconnect(
			_on_challenge_failed
		)


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("pause")
		and current_level != null
		and fail_screen == null
		and not results_open
		and not transition_in_progress
		and not current_level.completed
	):
		get_viewport().set_input_as_handled()

		if pause_menu == null:
			_show_pause()
		else:
			_resume()


func _clear_all() -> void:
	EventBus.dialogue_clear_requested.emit()
	GameState.clear_dialogue_state(true)

	transition_serial += 1
	results_open = false

	get_tree().paused = false
	AudioManager.restore_runtime_state()

	_detach_and_free(current_level)
	_detach_and_free(overlay)
	_detach_and_free(pause_menu)
	_detach_and_free(fail_screen)

	current_level = null
	overlay = null
	pause_menu = null
	fail_screen = null


func _detach_and_free(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	if node.get_parent() != null:
		node.get_parent().remove_child(node)

	node.queue_free()


func _finish_transition() -> void:
	transition_in_progress = false


func show_main_menu() -> void:
	if transition_in_progress:
		return

	transition_in_progress = true
	_clear_all()

	GameState.reset_run()
	current_level_index = -1

	var scene := load(
		"res://scenes/ui/main_menu.tscn"
	) as PackedScene

	if scene == null:
		push_error("Unable to load main menu scene.")
		call_deferred("_finish_transition")
		return

	var menu := scene.instantiate() as MainMenu

	if menu == null:
		push_error("Main menu root is not MainMenu.")
		call_deferred("_finish_transition")
		return

	overlay = menu
	ui_layer.add_child(menu)

	menu.start_requested.connect(_start_game)
	menu.level_requested.connect(_start_selected_level)

	call_deferred("_finish_transition")


func _start_game() -> void:
	if transition_in_progress:
		return

	GameState.reset_run()
	_load_level(0)


func _start_selected_level(index: int) -> void:
	if transition_in_progress:
		return

	if (
		index < 0
		or index >= SceneManager.LEVELS.size()
	):
		push_error(
			"Invalid direct level index: %d" % index
		)
		return

	GameState.reset_run()
	_prepare_direct_level_progress(index)
	_load_level(index)


func _prepare_direct_level_progress(index: int) -> void:
	# Mark the earlier stages as completed so a directly selected stage
	# behaves as if the player reached it through normal progression.
	for previous_index in range(index):
		if previous_index >= SceneManager.LEVEL_IDS.size():
			break

		var previous_id: String = (
			SceneManager.LEVEL_IDS[previous_index]
		)

		GameState.mark_level_completed(previous_id)

	# Sigils earned before each stage:
	#
	# Level 1 / Prologue       -> none
	# Level 2 / Gear Hall      -> none
	# Level 3 / Echo Archive   -> Time
	# Level 4 / Guardian Court -> Time + Echo
	# Level 5 / Sealed Heart   -> Time + Echo + Force
	if index >= 2:
		GameState.add_sigil("time")

	if index >= 3:
		GameState.add_sigil("echo")

	if index >= 4:
		GameState.add_sigil("force")


func _load_level(index: int) -> void:
	if transition_in_progress:
		return

	transition_in_progress = true
	_clear_all()

	var path := SceneManager.path_for_index(index)

	if path.is_empty():
		_create_ending()
		call_deferred("_finish_transition")
		return

	var packed := load(path) as PackedScene

	if packed == null:
		push_error("Unable to load " + path)
		transition_in_progress = false
		show_main_menu()
		return

	current_level_index = index
	current_level = packed.instantiate() as LevelManager

	if current_level == null:
		push_error(
			"Level root is not a LevelManager: " + path
		)
		transition_in_progress = false
		show_main_menu()
		return

	add_child(current_level)
	call_deferred("_finish_transition")


func can_restart_current_level() -> bool:
	return (
		current_level_index >= 0
		and current_level != null
		and is_instance_valid(current_level)
		and not results_open
		and not transition_in_progress
		and current_level.can_restart()
	)


func _restart_current_level() -> void:
	if not can_restart_current_level():
		return

	EventBus.dialogue_clear_requested.emit()
	GameState.clear_dialogue_state(true)

	if current_level.restart_in_place():
		_detach_and_free(fail_screen)
		fail_screen = null
		_resume()
		return

	_load_level(current_level_index)


func _on_challenge_failed(reason: String) -> void:
	if (
		fail_screen != null
		or current_level == null
		or results_open
		or transition_in_progress
		or current_level.completed
	):
		return

	var scene := load(
		"res://scenes/ui/fail_screen.tscn"
	) as PackedScene

	if scene == null:
		push_error("Unable to load fail screen.")
		return

	fail_screen = scene.instantiate() as FailScreen

	if fail_screen == null:
		push_error("Fail screen root is not FailScreen.")
		return

	ui_layer.add_child(fail_screen)
	fail_screen.setup(reason)
	fail_screen.retry_requested.connect(
		_restart_current_level
	)
	fail_screen.main_menu_requested.connect(
		show_main_menu
	)


func _on_level_completed(id: String) -> void:
	if (
		current_level == null
		or results_open
		or transition_in_progress
	):
		return

	if id != current_level.level_id:
		return

	results_open = true
	var request_serial := transition_serial

	await get_tree().create_timer(0.45).timeout

	if (
		request_serial != transition_serial
		or current_level == null
		or not is_instance_valid(current_level)
		or transition_in_progress
	):
		return

	var scene := load(
		"res://scenes/ui/results_screen.tscn"
	) as PackedScene

	if scene == null:
		push_error("Unable to load results screen.")
		results_open = false
		return

	var results := scene.instantiate() as ResultsScreen

	if results == null:
		push_error("Results screen root is not ResultsScreen.")
		results_open = false
		return

	overlay = results
	ui_layer.add_child(results)

	results.setup(
		current_level.level_title,
		current_level.time_remaining,
		current_level.uses_timer
	)

	results.continue_requested.connect(
		func() -> void:
			if transition_in_progress:
				return

			if id == "level_04":
				_show_ending()
			else:
				_load_level(
					current_level_index + 1
				)
	)

	results.main_menu_requested.connect(
		show_main_menu
	)


func _show_pause() -> void:
	if (
		pause_menu != null
		or transition_in_progress
		or results_open
	):
		return

	get_tree().paused = true

	var scene := load(
		"res://scenes/ui/pause_menu.tscn"
	) as PackedScene

	if scene == null:
		get_tree().paused = false
		push_error("Unable to load pause menu.")
		return

	pause_menu = scene.instantiate() as PauseMenu

	if pause_menu == null:
		get_tree().paused = false
		push_error("Pause menu root is not PauseMenu.")
		return

	ui_layer.add_child(pause_menu)

	pause_menu.resumed.connect(_resume)
	pause_menu.restart.connect(_restart_current_level)
	pause_menu.main_menu.connect(show_main_menu)


func _resume() -> void:
	get_tree().paused = false

	if (
		pause_menu != null
		and is_instance_valid(pause_menu)
	):
		pause_menu.queue_free()

	pause_menu = null


func _show_ending() -> void:
	if transition_in_progress:
		return

	transition_in_progress = true
	_clear_all()
	_create_ending()
	call_deferred("_finish_transition")


func _create_ending() -> void:
	var scene := load(
		"res://scenes/ui/ending_screen.tscn"
	) as PackedScene

	if scene == null:
		push_error("Unable to load ending screen.")
		return

	var ending := scene.instantiate() as EndingScreen

	if ending == null:
		push_error("Ending screen root is not EndingScreen.")
		return

	overlay = ending
	ui_layer.add_child(ending)
	ending.main_menu_requested.connect(show_main_menu)
