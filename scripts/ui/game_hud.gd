class_name GameHUD
extends CanvasLayer

signal dialogue_line_started(speaker: String, text: String)
signal dialogue_line_finished(speaker: String, text: String)
signal dialogue_queue_finished
signal dialogue_sequence_finished(sequence_id: int, completed: bool)

var root: Control
var status_panel: PanelContainer
var center_panel: PanelContainer
var objective_panel: PanelContainer
var charge_panel: PanelContainer
var health_label: Label
var health_icons: HBoxContainer
var sigil_label: Label
var sigil_icons: HBoxContainer
var star_count_label: Label
var state_label: Label
var timer_label: Label
var objective_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var portrait: TextureRect
var charge_bar: ProgressBar
var boss_panel: PanelContainer
var boss_name: Label
var boss_health: ProgressBar
var phase_label: Label
var truth_status_label: Label
var dialogue_queue: Array[Dictionary] = []
var dialogue_running := false
var current_dialogue: Dictionary = {}
var dialogue_generation := 0
var dialogue_manual_advance := false
var dialogue_processor_start_count := 0
var dialogue_sequence_counter := 0
var dialogue_locked_sequences: Dictionary = {}
var manual_dialogue_advance_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UIFactory.apply_font(root)
	_build_status_panel()
	_build_center_panel()
	_build_objective_panel()
	_build_charge_panel()
	_build_dialogue_panel()
	_build_boss_panel()
	EventBus.objective_changed.connect(set_objective)
	if not EventBus.dialogue_requested.is_connected(queue_dialogue):
		EventBus.dialogue_requested.connect(queue_dialogue)
	if not EventBus.dialogue_clear_requested.is_connected(clear_dialogue_queue):
		EventBus.dialogue_clear_requested.connect(clear_dialogue_queue)
	EventBus.player_damaged.connect(
		func(_amount: int) -> void:
			update_stats()
	)
	EventBus.player_health_changed.connect(
		func(_current: int, _maximum: int) -> void:
			update_stats()
	)
	EventBus.kick_charge_changed.connect(
		func(value: float) -> void:
			charge_bar.value = value
	)
	EventBus.star_ammo_changed.connect(
		func(_current: int, _maximum: int) -> void:
			update_stats()
	)
	update_stats()

func _exit_tree() -> void:
	if EventBus.dialogue_requested.is_connected(queue_dialogue):
		EventBus.dialogue_requested.disconnect(queue_dialogue)
	if EventBus.dialogue_clear_requested.is_connected(clear_dialogue_queue):
		EventBus.dialogue_clear_requested.disconnect(clear_dialogue_queue)
	clear_dialogue_queue()

func _input(event: InputEvent) -> void:
	if not manual_dialogue_advance_enabled:
		return
	if not GameState.dialogue_active:
		return
	if not _is_dialogue_advance_event(event):
		return
	if dialogue_running and not current_dialogue.is_empty():
		request_dialogue_advance()
	get_viewport().set_input_as_handled()

func _is_dialogue_advance_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		var allowed_keys: Array[int] = [KEY_E, KEY_ENTER, KEY_KP_ENTER]
		return (
			key_event.keycode in allowed_keys
			or key_event.physical_keycode in allowed_keys
		)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return (
			mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
		)
	return false

func _build_status_panel() -> void:
	status_panel = PanelContainer.new()
	var panel := status_panel
	panel.position = Vector2(28, 24)
	panel.size = Vector2(430, 208)
	panel.add_theme_stylebox_override(
		"panel", UIFactory.panel_style(Color(0.03, 0.05, 0.08, 0.84))
	)
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	health_label = Label.new()
	health_label.text = "HEALTH"
	health_label.add_theme_font_size_override("font_size", 20)
	box.add_child(health_label)
	health_icons = HBoxContainer.new()
	health_icons.add_theme_constant_override("separation", 6)
	box.add_child(health_icons)
	var star_row := HBoxContainer.new()
	star_row.add_theme_constant_override("separation", 12)
	box.add_child(star_row)
	var star_title := Label.new()
	star_title.text = "THROWING STARS"
	star_title.add_theme_font_size_override("font_size", 17)
	star_row.add_child(star_title)
	star_count_label = Label.new()
	star_count_label.add_theme_font_size_override("font_size", 19)
	star_count_label.add_theme_color_override("font_color", Color("ffe36a"))
	star_row.add_child(star_count_label)
	sigil_label = Label.new()
	sigil_label.text = "SIGILS"
	sigil_label.add_theme_font_size_override("font_size", 17)
	box.add_child(sigil_label)
	sigil_icons = HBoxContainer.new()
	sigil_icons.add_theme_constant_override("separation", 6)
	box.add_child(sigil_icons)

func _build_center_panel() -> void:
	center_panel = PanelContainer.new()
	var panel := center_panel
	panel.position = Vector2(710, 22)
	panel.size = Vector2(500, 150)
	panel.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style_for(
			"timer_panel", Color(0.02, 0.04, 0.07, 0.72)
		),
	)
	root.add_child(panel)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(center)
	state_label = UIFactory.make_title("WORLD FROZEN", 35)
	center.add_child(state_label)
	timer_label = UIFactory.make_title("", 30)
	center.add_child(timer_label)

func _build_objective_panel() -> void:
	objective_panel = PanelContainer.new()
	var panel := objective_panel
	panel.position = Vector2(1390, 24)
	panel.size = Vector2(500, 152)
	panel.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style_for(
			"objective_panel", Color(0.03, 0.05, 0.08, 0.84)
		),
	)
	root.add_child(panel)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 21)
	panel.add_child(objective_label)

func _build_charge_panel() -> void:
	charge_panel = PanelContainer.new()
	var panel := charge_panel
	panel.position = Vector2(1340, 884)
	panel.size = Vector2(550, 156)
	panel.add_theme_stylebox_override(
		"panel", UIFactory.panel_style(Color(0.03, 0.05, 0.08, 0.84))
	)
	root.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var icon_row := HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_row.add_theme_constant_override("separation", 18)
	icon_row.add_child(_icon_or_label("kick_icon", "J  KICK", Vector2(52, 52)))
	icon_row.add_child(
		_icon_or_label(
			"charged_kick_icon", "K  CHARGED", Vector2(52, 52)
		)
	)
	icon_row.add_child(_icon_or_label("sword_icon", "L  SWORD", Vector2(52, 52)))
	icon_row.add_child(_icon_or_label("star_icon", "I  STAR", Vector2(52, 52)))
	box.add_child(icon_row)
	charge_bar = ProgressBar.new()
	charge_bar.min_value = 0.0
	charge_bar.max_value = 1.0
	charge_bar.show_percentage = false
	box.add_child(charge_bar)

func _build_dialogue_panel() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.position = Vector2(320, 210)
	dialogue_panel.size = Vector2(1280, 150)
	dialogue_panel.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style_for(
			"dialogue_box",
			Color(0.025, 0.04, 0.075, 0.96),
			Color("60b8ca"),
		),
	)
	dialogue_panel.visible = false
	root.add_child(dialogue_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	dialogue_panel.add_child(row)
	portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(130,170);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.visible=false;row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(box)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 26)
	speaker_label.add_theme_color_override("font_color", Color("72d8eb"))
	box.add_child(speaker_label)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 25)
	dialogue_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_child(dialogue_label)

func _build_boss_panel() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.position = Vector2(610, 175)
	boss_panel.size = Vector2(700, 120)
	boss_panel.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style(
			Color(0.05, 0.025, 0.07, 0.9), Color("a76cd0")
		),
	)
	boss_panel.visible = false
	root.add_child(boss_panel)
	var box := VBoxContainer.new()
	boss_panel.add_child(box)
	boss_name = Label.new()
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", 25)
	box.add_child(boss_name)
	boss_health = ProgressBar.new()
	boss_health.show_percentage = false
	box.add_child(boss_health)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(phase_label)
	truth_status_label = Label.new()
	truth_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	truth_status_label.add_theme_color_override("font_color", Color("ffe36a"))
	truth_status_label.visible = false
	box.add_child(truth_status_label)

func _icon_or_label(key: String, fallback: String, size: Vector2) -> Control:
	var texture := AssetRegistry.load_texture(key)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return icon
	var label := Label.new()
	label.text = fallback
	label.custom_minimum_size = Vector2(maxf(size.x, 90.0), size.y)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func update_stats() -> void:
	_clear_container(health_icons)
	var health_texture_available := (
		AssetRegistry.has_asset("health_full", "Texture2D")
		and AssetRegistry.has_asset("health_empty", "Texture2D")
	)
	for i in GameState.max_health:
		if health_texture_available:
			health_icons.add_child(
				_icon_or_label(
					"health_full" if i < GameState.current_health
					else "health_empty",
					"◆" if i < GameState.current_health else "◇",
					Vector2(34, 34),
				)
			)
		else:
			var heart := Label.new()
			heart.text = "◆" if i < GameState.current_health else "◇"
			heart.add_theme_font_size_override("font_size", 24)
			health_icons.add_child(heart)

	star_count_label.text = "★  %d / %d" % [GameState.current_stars, GameState.max_stars]

	_clear_container(sigil_icons)
	var collected := 0
	for key: String in GameState.sigils.keys():
		if bool(GameState.sigils[key]):
			collected += 1
			sigil_icons.add_child(
				_icon_or_label(
					"sigil_" + key,
					key.to_upper(),
					Vector2(34, 34),
				)
			)
	if collected == 0:
		var none := Label.new()
		none.text = "NONE"
		sigil_icons.add_child(none)


func set_gameplay_hud_visible(visible: bool, show_state: bool = true) -> void:
	if status_panel != null:
		status_panel.visible = visible
	if objective_panel != null:
		objective_panel.visible = visible
	if charge_panel != null:
		charge_panel.visible = visible
	if center_panel != null:
		center_panel.visible = visible and show_state
	if not visible:
		timer_label.visible = false

func set_state_panel_visible(visible: bool) -> void:
	if center_panel != null:
		center_panel.visible = visible

func set_manual_dialogue_advance_enabled(enabled: bool) -> void:
	manual_dialogue_advance_enabled = enabled

func set_world_state(frozen: bool) -> void:
	state_label.text = "WORLD FROZEN" if frozen else "KICKOFF!"
	state_label.modulate = Color("aeb8c8") if frozen else Color("ffe17a")
	if not frozen:
		var tween := create_tween()
		tween.tween_interval(1.1)
		tween.tween_property(state_label, "modulate:a", 0.0, 0.4)
		tween.tween_callback(_clear_state_label)

func _clear_state_label() -> void:
	state_label.text = ""
	state_label.modulate.a = 1.0

func set_timer(value: float, visible_timer: bool) -> void:
	timer_label.visible = visible_timer
	timer_label.text = "%05.1f" % maxf(value, 0.0)

func set_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE\n" + text

func queue_dialogue(
	speaker: String,
	text: String,
	duration: float,
	priority: int = 10,
	portrait_key: String = "",
	sequence_id: int = 0,
	sequence_last: bool = false
) -> void:
	var entry := {
		"speaker": speaker,
		"text": text,
		"duration": maxf(duration, 0.1),
		"priority": priority,
		"portrait_key": portrait_key,
		"sequence_id": sequence_id,
		"sequence_last": sequence_last,
	}
	var insert_at := dialogue_queue.size()
	for index in dialogue_queue.size():
		if int(dialogue_queue[index].get("priority", 0)) < priority:
			insert_at = index
			break
	dialogue_queue.insert(insert_at, entry)
	GameState.set_dialogue_active(true)
	if not dialogue_running:
		call_deferred("_process_dialogue_queue")

func show_dialogue(speaker: String, text: String, duration: float) -> void:
	queue_dialogue(speaker, text, duration)

func show_dialogue_sequence(
	lines: Array, lock_player: bool = false
) -> bool:
	if lines.is_empty():
		return true
	dialogue_sequence_counter += 1
	var sequence_id := dialogue_sequence_counter
	if lock_player:
		dialogue_locked_sequences[sequence_id] = true
		if dialogue_locked_sequences.size() == 1:
			EventBus.cutscene_started.emit()
	for index in lines.size():
		var line: Dictionary = lines[index]
		queue_dialogue(
			str(line.get("speaker", "")),
			str(line.get("text", "")),
			float(line.get("duration", 1.5)),
			int(line.get("priority", 20)),
			str(line.get("portrait_key", "")),
			sequence_id,
			index == lines.size() - 1,
		)
	while is_inside_tree():
		var result: Array = await dialogue_sequence_finished
		if int(result[0]) == sequence_id:
			return bool(result[1])
	return false

func _process_dialogue_queue() -> void:
	if dialogue_running:
		return
	dialogue_running = true
	GameState.set_dialogue_active(true)
	dialogue_processor_start_count += 1
	var token := dialogue_generation
	while token == dialogue_generation and not dialogue_queue.is_empty():
		current_dialogue = dialogue_queue.pop_front()
		dialogue_manual_advance = false
		_display_dialogue_entry(current_dialogue)
		dialogue_line_started.emit(
			str(current_dialogue.get("speaker", "")),
			str(current_dialogue.get("text", "")),
		)
		var elapsed := 0.0
		var duration := float(current_dialogue.get("duration", 0.1))
		while (
			token == dialogue_generation
			and is_inside_tree()
			and not dialogue_manual_advance
			and elapsed < duration
		):
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		if token != dialogue_generation or not is_inside_tree():
			return
		var finished_entry := current_dialogue
		current_dialogue = {}
		dialogue_panel.visible = false
		dialogue_line_finished.emit(
			str(finished_entry.get("speaker", "")),
			str(finished_entry.get("text", "")),
		)
		if bool(finished_entry.get("sequence_last", false)):
			_finish_dialogue_sequence(
				int(finished_entry.get("sequence_id", 0)), true
			)
	if token != dialogue_generation:
		return
	dialogue_running = false
	current_dialogue = {}
	dialogue_panel.visible = false
	GameState.set_dialogue_active(false)
	dialogue_queue_finished.emit()

func _display_dialogue_entry(entry: Dictionary) -> void:
	var speaker := str(entry.get("speaker", ""))
	speaker_label.text = speaker
	dialogue_label.text = str(entry.get("text", ""))
	var portrait_key := str(entry.get("portrait_key", ""))
	if portrait_key.is_empty():
		if speaker.to_upper() == "ARIN":
			portrait_key = "arin_portrait"
		elif speaker.to_upper() == "NIKO":
			portrait_key = "niko_portrait"
	var portrait_texture := (
		AssetRegistry.load_texture(portrait_key)
		if not portrait_key.is_empty()
		else null
	)
	portrait.texture = portrait_texture
	portrait.visible = portrait_texture != null
	dialogue_panel.visible = true

func request_dialogue_advance() -> bool:
	if (
		not dialogue_running
		or current_dialogue.is_empty()
		or dialogue_manual_advance
	):
		return false
	dialogue_manual_advance = true
	return true

func clear_dialogue_queue() -> void:
	dialogue_generation += 1
	var sequence_ids: Dictionary = {}
	if not current_dialogue.is_empty():
		var current_id := int(current_dialogue.get("sequence_id", 0))
		if current_id > 0:
			sequence_ids[current_id] = true
	for entry in dialogue_queue:
		var sequence_id := int(entry.get("sequence_id", 0))
		if sequence_id > 0:
			sequence_ids[sequence_id] = true
	dialogue_queue.clear()
	current_dialogue = {}
	dialogue_running = false
	dialogue_manual_advance = false
	if is_instance_valid(dialogue_panel):
		dialogue_panel.visible = false
	for sequence_id in sequence_ids.keys():
		_finish_dialogue_sequence(int(sequence_id), false)
	if not dialogue_locked_sequences.is_empty():
		dialogue_locked_sequences.clear()
		EventBus.cutscene_ended.emit()
	GameState.clear_dialogue_state(true)

func _finish_dialogue_sequence(sequence_id: int, completed: bool) -> void:
	if sequence_id <= 0:
		return
	if dialogue_locked_sequences.has(sequence_id):
		dialogue_locked_sequences.erase(sequence_id)
		if dialogue_locked_sequences.is_empty():
			EventBus.cutscene_ended.emit()
	dialogue_sequence_finished.emit(sequence_id, completed)

func has_pending_dialogue() -> bool:
	return dialogue_running or not dialogue_queue.is_empty()

func show_message(text: String, duration: float = 1.5) -> void:
	queue_dialogue("SYSTEM", text, duration, 0)

func show_boss(name: String, maximum: int, phase: String) -> void:
	boss_panel.visible = true
	boss_name.text = name
	boss_health.max_value = maximum
	boss_health.value = maximum
	phase_label.text = phase

func update_boss(current: int, maximum: int) -> void:
	boss_health.max_value = maximum
	boss_health.value = current

func set_boss_phase(text: String) -> void:
	phase_label.text = text

func set_truth_pulse_status(text: String) -> void:
	truth_status_label.text = text
	truth_status_label.visible = not text.is_empty()

func hide_boss() -> void:
	boss_panel.visible = false
	set_truth_pulse_status("")
