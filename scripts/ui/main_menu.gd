class_name MainMenu
extends Control

signal start_requested
signal level_requested(index: int)

var page: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIFactory.apply_font(self)
	_show_home()
	AudioManager.play_music("main_menu_music")


func _clear() -> void:
	if page != null and is_instance_valid(page):
		page.queue_free()

	page = null


func _base_panel() -> VBoxContainer:
	_clear()

	var shade := ColorRect.new()
	shade.color = Color("0b1423")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	page = shade

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270.0, -390.0)
	panel.size = Vector2(540.0, 780.0)
	shade.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	return box


func _show_home() -> void:
	var box := _base_panel()

	var logo_texture := AssetRegistry.load_texture("logo")

	if logo_texture != null:
		var logo := TextureRect.new()
		logo.texture = logo_texture
		logo.custom_minimum_size = Vector2(420.0, 150.0)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(logo)
	else:
		box.add_child(UIFactory.make_title("THE FIRST KICK", 58))

		var subtitle := UIFactory.make_title("ECHOES BENEATH", 28)
		subtitle.add_theme_color_override("font_color", Color("76c7d7"))
		box.add_child(subtitle)

	var line := Label.new()
	line.text = "Every challenge begins with a KICKOFF."
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 19)
	box.add_child(line)

	var start_button := UIFactory.make_button("Start Game")
	start_button.pressed.connect(_start)
	box.add_child(start_button)

	var level_select_button := UIFactory.make_button("Level Select")
	level_select_button.pressed.connect(_show_level_select)
	box.add_child(level_select_button)

	var how_button := UIFactory.make_button("How to Play")
	how_button.pressed.connect(_how)
	box.add_child(how_button)

	var settings_button := UIFactory.make_button("Settings")
	settings_button.pressed.connect(_settings)
	box.add_child(settings_button)

	var credits_button := UIFactory.make_button("Credits")
	credits_button.pressed.connect(_credits)
	box.add_child(credits_button)

	var exit_button := UIFactory.make_button("Exit")

	if OS.has_feature("web"):
		exit_button.disabled = true
		exit_button.tooltip_text = ("Browser builds are closed from the browser tab.")
	else:
		exit_button.pressed.connect(func() -> void: get_tree().quit())

	box.add_child(exit_button)


func _show_level_select() -> void:
	var box := _base_panel()

	box.add_child(UIFactory.make_title("LEVEL SELECT", 44))

	var description := Label.new()
	description.text = ("Choose any stage and play it directly.")
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18)
	box.add_child(description)

	_add_level_button(box, "Level 1 — Prologue Forest", 0)

	_add_level_button(box, "Level 2 — Hall of Still Gears", 1)

	_add_level_button(box, "Level 3 — Archive of Echoes", 2)

	_add_level_button(box, "Level 4 — Guardian Court", 3)

	_add_level_button(box, "Level 5 — The Sealed Heart", 4)

	var back := UIFactory.make_button("Back")
	back.pressed.connect(_show_home)
	box.add_child(back)


func _add_level_button(box: VBoxContainer, title: String, index: int) -> void:
	var button := UIFactory.make_button(title)
	button.pressed.connect(_request_level.bind(index))
	box.add_child(button)


func _request_level(index: int) -> void:
	level_requested.emit(index)


func _start() -> void:
	start_requested.emit()


func _how() -> void:
	var box := _base_panel()

	box.add_child(UIFactory.make_title("HOW TO PLAY", 44))

	var text := Label.new()
	text.text = (
		"Move with A and D.\n"
		+ "Jump with Space and leap over low attacks.\n"
		+ "Kick with J or Left Mouse.\n"
		+ "Charge a kick with K or Right Mouse.\n"
		+ "Throw a limited star with I.\n"
		+ "Press E to read clues or interact.\n"
		+ "Press R to restart the current challenge.\n\n"
		+ "Ancient mechanisms respond only to kicks."
	)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 22)
	text.custom_minimum_size = Vector2(440.0, 390.0)
	box.add_child(text)

	var back := UIFactory.make_button("Back")
	back.pressed.connect(_show_home)
	box.add_child(back)


func _settings() -> void:
	var box := _base_panel()

	box.add_child(UIFactory.make_title("SETTINGS", 44))

	_add_settings_controls(box)

	var back := UIFactory.make_button("Back")
	back.pressed.connect(_show_home)
	box.add_child(back)


func _credits() -> void:
	var box := _base_panel()

	box.add_child(UIFactory.make_title("CREDITS", 44))

	var text := Label.new()
	text.text = (
		"Game Jam prototype\n\n"
		+ "Design, code and final art:\n"
		+ "Your three-person team\n\n"
		+ "The First Kick: Echoes Beneath"
	)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 21)
	text.custom_minimum_size = Vector2(440.0, 380.0)
	box.add_child(text)

	var back := UIFactory.make_button("Back")
	back.pressed.connect(_show_home)
	box.add_child(back)


func _add_settings_controls(box: VBoxContainer) -> void:
	var music_label := Label.new()
	music_label.text = "Music Volume"
	music_label.add_theme_font_size_override("font_size", 22)
	box.add_child(music_label)

	var music := HSlider.new()
	music.min_value = 0.0
	music.max_value = 1.0
	music.step = 0.01
	music.value = AudioManager.music_volume
	music.custom_minimum_size = Vector2(410.0, 40.0)
	music.value_changed.connect(AudioManager.set_music_volume)
	box.add_child(music)

	var sfx_label := Label.new()
	sfx_label.text = "SFX Volume"
	sfx_label.add_theme_font_size_override("font_size", 22)
	box.add_child(sfx_label)

	var sfx := HSlider.new()
	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.01
	sfx.value = AudioManager.sfx_volume
	sfx.custom_minimum_size = Vector2(410.0, 40.0)
	sfx.value_changed.connect(AudioManager.set_sfx_volume)
	box.add_child(sfx)

	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen.add_theme_font_size_override("font_size", 22)
	fullscreen.toggled.connect(AudioManager.set_fullscreen)
	box.add_child(fullscreen)
