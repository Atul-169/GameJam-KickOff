class_name MainMenu
extends Control


signal start_requested
signal level_requested(index: int)


const BACKGROUND_PATH := (
	"res://assets/ui/main_menu_background.png"
)

const HOME_PANEL_SIZE := Vector2(370.0, 335.0)
const SUB_PANEL_SIZE := Vector2(620.0, 500.0)


var page: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	UIFactory.apply_font(self)

	_show_home()
	AudioManager.play_music("main_menu_music")


# =========================================================
# PAGE AND BACKGROUND
# =========================================================

func _clear() -> void:
	if page == null:
		return

	if not is_instance_valid(page):
		page = null
		return

	if page.get_parent() != null:
		page.get_parent().remove_child(page)

	page.queue_free()
	page = null


func _create_background() -> Control:
	_clear()

	var background_texture := load(
		BACKGROUND_PATH
	) as Texture2D

	var root: Control

	if background_texture != null:
		var background := TextureRect.new()

		background.texture = background_texture
		background.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)
		background.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_COVERED
		)
		background.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		background.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)

		root = background
	else:
		push_warning(
			"Main menu background was not found: "
			+ BACKGROUND_PATH
		)

		var fallback := ColorRect.new()
		fallback.color = Color("0d0909")

		fallback.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)

		root = fallback

	add_child(root)
	page = root

	# পুরো screen-এর উপরে হালকা dark layer
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.01, 0.01, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	shade.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.add_child(shade)

	return root


func _base_panel(home_page: bool = false) -> VBoxContainer:
	var root := _create_background()

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()

	if home_page:
		panel_style.bg_color = Color(
			0.035,
			0.015,
			0.015,
			0.52
		)
	else:
		panel_style.bg_color = Color(
			0.025,
			0.012,
			0.012,
			0.86
		)

	panel_style.border_color = Color(
		0.43,
		0.17,
		0.13,
		0.90
	)

	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(7)

	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 18
	panel_style.content_margin_bottom = 18

	panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	if home_page:
		# Title-এর নিচে, screen-এর ডান পাশে
		panel.set_anchors_preset(
			Control.PRESET_TOP_RIGHT
		)

		panel.position = Vector2(
			-HOME_PANEL_SIZE.x - 328.0,
			450.0
		)

		panel.size = HOME_PANEL_SIZE
	else:
		# Level Select, Settings ইত্যাদি screen-এর মাঝে
		panel.set_anchors_preset(
			Control.PRESET_CENTER
		)

		panel.position = Vector2(
			-SUB_PANEL_SIZE.x / 2.0,
			-SUB_PANEL_SIZE.y / 2.0
		)

		panel.size = SUB_PANEL_SIZE

	root.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	if home_page:
		box.add_theme_constant_override(
			"separation",
			7
		)
	else:
		box.add_theme_constant_override(
			"separation",
			12
		)

	panel.add_child(box)

	return box


# =========================================================
# CUSTOM UI DESIGN
# =========================================================

func _make_title(
	title_text: String,
	font_size: int = 40
) -> Label:
	var title := Label.new()

	title.text = title_text
	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		font_size
	)

	title.add_theme_color_override(
		"font_color",
		Color("ead8c0")
	)

	title.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.75)
	)

	title.add_theme_constant_override(
		"shadow_offset_x",
		2
	)

	title.add_theme_constant_override(
		"shadow_offset_y",
		2
	)

	return title


func _make_description(
	description_text: String,
	font_size: int = 18
) -> Label:
	var label := Label.new()

	label.text = description_text
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		Color("d8c7b5")
	)

	return label


func _make_button(
	button_text: String,
	wide: bool = false
) -> Button:
	var button := Button.new()

	button.text = button_text
	button.focus_mode = Control.FOCUS_ALL

	if wide:
		button.custom_minimum_size = Vector2(
			510.0,
			45.0
		)
	else:
		button.custom_minimum_size = Vector2(
			320.0,
			42.0
		)

	button.add_theme_font_size_override(
		"font_size",
		19
	)

	button.add_theme_color_override(
		"font_color",
		Color("e8d8c5")
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color("fff2df")
	)

	button.add_theme_color_override(
		"font_pressed_color",
		Color("ffffff")
	)

	button.add_theme_color_override(
		"font_focus_color",
		Color("fff2df")
	)

	button.add_theme_color_override(
		"font_disabled_color",
		Color(0.55, 0.50, 0.47, 0.75)
	)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(
		0.08,
		0.025,
		0.02,
		0.78
	)

	normal.border_color = Color(
		0.40,
		0.13,
		0.10,
		0.95
	)

	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)

	var hover := normal.duplicate() as StyleBoxFlat

	hover.bg_color = Color(
		0.27,
		0.065,
		0.045,
		0.94
	)

	hover.border_color = Color(
		0.72,
		0.28,
		0.20,
		1.0
	)

	hover.set_border_width_all(2)

	var pressed := normal.duplicate() as StyleBoxFlat

	pressed.bg_color = Color(
		0.16,
		0.025,
		0.02,
		1.0
	)

	pressed.border_color = Color(
		0.82,
		0.31,
		0.22,
		1.0
	)

	pressed.set_border_width_all(2)

	var focus := hover.duplicate() as StyleBoxFlat
	focus.bg_color = Color(
		0.21,
		0.045,
		0.035,
		0.96
	)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(
		0.05,
		0.04,
		0.04,
		0.55
	)

	disabled.border_color = Color(
		0.22,
		0.19,
		0.18,
		0.65
	)

	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"focus",
		focus
	)

	button.add_theme_stylebox_override(
		"disabled",
		disabled
	)

	button.mouse_entered.connect(
		_on_button_mouse_entered.bind(button)
	)

	button.mouse_exited.connect(
		_on_button_mouse_exited.bind(button)
	)

	return button


func _on_button_mouse_entered(button: Button) -> void:
	if button.disabled:
		return

	var tween := create_tween()

	tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		button,
		"scale",
		Vector2(1.025, 1.025),
		0.10
	)


func _on_button_mouse_exited(button: Button) -> void:
	if not is_instance_valid(button):
		return

	var tween := create_tween()

	tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		button,
		"scale",
		Vector2.ONE,
		0.10
	)


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.custom_minimum_size = Vector2(
		0.0,
		8.0
	)

	return separator


# =========================================================
# HOME PAGE
# =========================================================

func _show_home() -> void:
	var box := _base_panel(true)

	# Background image-এর মধ্যে title এবং logo আছে।
	# তাই এখানে আলাদাভাবে title যোগ করা হয়নি।

	var start_button := _make_button(
		"START GAME"
	)

	start_button.pressed.connect(_start)
	box.add_child(start_button)

	var level_select_button := _make_button(
		"LEVEL SELECT"
	)

	level_select_button.pressed.connect(
		_show_level_select
	)

	box.add_child(level_select_button)

	var how_button := _make_button(
		"HOW TO PLAY"
	)

	how_button.pressed.connect(_how)
	box.add_child(how_button)

	var settings_button := _make_button(
		"SETTINGS"
	)

	settings_button.pressed.connect(_settings)
	box.add_child(settings_button)

	var credits_button := _make_button(
		"CREDITS"
	)

	credits_button.pressed.connect(_credits)
	box.add_child(credits_button)

	var exit_button := _make_button(
		"EXIT"
	)

	if OS.has_feature("web"):
		exit_button.disabled = true
		exit_button.tooltip_text = (
			"Close the browser tab to exit the game."
		)
	else:
		exit_button.pressed.connect(
			func() -> void:
				get_tree().quit()
		)

	box.add_child(exit_button)

	start_button.grab_focus()


# =========================================================
# LEVEL SELECT
# =========================================================

func _show_level_select() -> void:
	var box := _base_panel()

	box.add_child(
		_make_title(
			"LEVEL SELECT",
			40
		)
	)

	box.add_child(
		_make_description(
			"Choose a stage and begin the journey.",
			18
		)
	)

	box.add_child(_make_separator())

	_add_level_button(
		box,
		"LEVEL 1 — PROLOGUE FOREST",
		0
	)

	_add_level_button(
		box,
		"LEVEL 2 — HALL OF STILL GEARS",
		1
	)

	_add_level_button(
		box,
		"LEVEL 3 — ARCHIVE OF ECHOES",
		2
	)

	_add_level_button(
		box,
		"LEVEL 4 — GUARDIAN COURT",
		3
	)

	_add_level_button(
		box,
		"LEVEL 5 — THE SEALED HEART",
		4
	)

	box.add_child(_make_separator())

	var back := _make_button(
		"BACK",
		true
	)

	back.pressed.connect(_show_home)
	box.add_child(back)

	back.focus_neighbor_bottom = back.get_path()


func _add_level_button(
	box: VBoxContainer,
	title: String,
	index: int
) -> void:
	var button := _make_button(
		title,
		true
	)

	button.pressed.connect(
		_request_level.bind(index)
	)

	box.add_child(button)


func _request_level(index: int) -> void:
	level_requested.emit(index)


func _start() -> void:
	start_requested.emit()


# =========================================================
# HOW TO PLAY
# =========================================================

func _how() -> void:
	var box := _base_panel()

	box.add_child(
		_make_title(
			"HOW TO PLAY",
			40
		)
	)

	var text := Label.new()

	text.text = (
		"Move                 A / D\n"
		+ "Jump                 SPACE\n"
		+ "Kick                  J / LEFT MOUSE\n"
		+ "Charged Kick     K / RIGHT MOUSE\n"
		+ "Throw Star         I\n"
		+ "Interact             E\n"
		+ "Restart              R\n\n"
		+ "Ancient mechanisms respond only to kicks."
	)

	text.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	text.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	text.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	text.add_theme_font_size_override(
		"font_size",
		20
	)

	text.add_theme_color_override(
		"font_color",
		Color("e0cfbc")
	)

	text.custom_minimum_size = Vector2(
		500.0,
		310.0
	)

	box.add_child(text)

	var back := _make_button(
		"BACK",
		true
	)

	back.pressed.connect(_show_home)
	box.add_child(back)


# =========================================================
# SETTINGS
# =========================================================

func _settings() -> void:
	var box := _base_panel()

	box.add_child(
		_make_title(
			"SETTINGS",
			40
		)
	)

	box.add_child(_make_separator())

	_add_settings_controls(box)

	box.add_child(_make_separator())

	var back := _make_button(
		"BACK",
		true
	)

	back.pressed.connect(_show_home)
	box.add_child(back)


func _add_settings_controls(
	box: VBoxContainer
) -> void:
	var music_label := _make_description(
		"MUSIC VOLUME",
		20
	)

	music_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	box.add_child(music_label)

	var music := HSlider.new()

	music.min_value = 0.0
	music.max_value = 1.0
	music.step = 0.01
	music.value = AudioManager.music_volume

	music.custom_minimum_size = Vector2(
		510.0,
		42.0
	)

	music.value_changed.connect(
		AudioManager.set_music_volume
	)

	box.add_child(music)

	var sfx_label := _make_description(
		"SFX VOLUME",
		20
	)

	sfx_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	box.add_child(sfx_label)

	var sfx := HSlider.new()

	sfx.min_value = 0.0
	sfx.max_value = 1.0
	sfx.step = 0.01
	sfx.value = AudioManager.sfx_volume

	sfx.custom_minimum_size = Vector2(
		510.0,
		42.0
	)

	sfx.value_changed.connect(
		AudioManager.set_sfx_volume
	)

	box.add_child(sfx)

	var fullscreen := CheckButton.new()

	fullscreen.text = "FULLSCREEN"

	fullscreen.button_pressed = (
		DisplayServer.window_get_mode()
		== DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	fullscreen.add_theme_font_size_override(
		"font_size",
		20
	)

	fullscreen.add_theme_color_override(
		"font_color",
		Color("e0cfbc")
	)

	fullscreen.toggled.connect(
		AudioManager.set_fullscreen
	)

	box.add_child(fullscreen)


# =========================================================
# CREDITS
# =========================================================

func _credits() -> void:
	var box := _base_panel()

	box.add_child(
		_make_title(
			"CREDITS",
			40
		)
	)

	var text := Label.new()

	text.text = (
		"THE FIRST KICK: ECHOES BENEATH\n\n"
		+ "Created for the Game Jam\n\n"
		+ "Game Design, Programming and Art\n"
		+ "Your Three-Person Team\n\n"
		+ "Thank you for playing."
	)

	text.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	text.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	text.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	text.add_theme_font_size_override(
		"font_size",
		20
	)

	text.add_theme_color_override(
		"font_color",
		Color("e0cfbc")
	)

	text.custom_minimum_size = Vector2(
		500.0,
		320.0
	)

	box.add_child(text)

	var back := _make_button(
		"BACK",
		true
	)

	back.pressed.connect(_show_home)
	box.add_child(back)
