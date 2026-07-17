class_name SettingsMenu
extends PanelContainer
signal closed
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;custom_minimum_size=Vector2(520,560);add_theme_stylebox_override("panel",UIFactory.panel_style());var box:=VBoxContainer.new();box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",18);add_child(box);box.add_child(UIFactory.make_title("SETTINGS",42))
 var mlabel:=Label.new();mlabel.text="Music Volume";mlabel.add_theme_font_size_override("font_size",22);box.add_child(mlabel);var music:=HSlider.new();music.min_value=0;music.max_value=1;music.step=.01;music.value=AudioManager.music_volume;music.custom_minimum_size=Vector2(400,40);music.value_changed.connect(AudioManager.set_music_volume);box.add_child(music)
 var slabel:=Label.new();slabel.text="SFX Volume";slabel.add_theme_font_size_override("font_size",22);box.add_child(slabel);var sfx:=HSlider.new();sfx.min_value=0;sfx.max_value=1;sfx.step=.01;sfx.value=AudioManager.sfx_volume;sfx.custom_minimum_size=Vector2(400,40);sfx.value_changed.connect(AudioManager.set_sfx_volume);box.add_child(sfx)
 var full:=CheckButton.new();full.text="Fullscreen";full.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;full.add_theme_font_size_override("font_size",22);full.toggled.connect(AudioManager.set_fullscreen);box.add_child(full)
 var back:=UIFactory.make_button("Back");back.pressed.connect(func()->void:closed.emit());box.add_child(back)
