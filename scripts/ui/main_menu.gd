class_name MainMenu
extends Control
signal start_requested
var page:Control
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);UIFactory.apply_font(self);_show_home();AudioManager.play_music("main_menu_music")
func _clear()->void:
 if page!=null and is_instance_valid(page):page.queue_free()
func _base_panel()->VBoxContainer:
 _clear();var shade:=ColorRect.new();shade.color=Color("0b1423");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade);page=shade
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",UIFactory.panel_style());panel.set_anchors_preset(Control.PRESET_CENTER);panel.position=Vector2(-270,-390);panel.size=Vector2(540,780);shade.add_child(panel)
 var box:=VBoxContainer.new();box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",16);panel.add_child(box);return box
func _show_home()->void:
 var box:=_base_panel()
 var logo_texture:=AssetRegistry.load_texture("logo")
 if logo_texture!=null:
  var logo:=TextureRect.new();logo.texture=logo_texture;logo.custom_minimum_size=Vector2(420,150);logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;box.add_child(logo)
 else:
  box.add_child(UIFactory.make_title("THE FIRST KICK",58));var sub:=UIFactory.make_title("ECHOES BENEATH",28);sub.add_theme_color_override("font_color",Color("76c7d7"));box.add_child(sub)
 var line:=Label.new();line.text="Every challenge begins with a KICKOFF.";line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.add_theme_font_size_override("font_size",19);box.add_child(line)
 for data:Array in [["Start Game",_start],["How to Play",_how],["Settings",_settings],["Credits",_credits]]:
  var button:=UIFactory.make_button(data[0]);button.pressed.connect(data[1]);box.add_child(button)
 var exit_button:=UIFactory.make_button("Exit")
 if OS.has_feature("web"):exit_button.disabled=true;exit_button.tooltip_text="Browser builds are closed from the browser tab."
 else:exit_button.pressed.connect(func()->void:get_tree().quit())
 box.add_child(exit_button)
func _start()->void:start_requested.emit()
func _how()->void:
 var box:=_base_panel();box.add_child(UIFactory.make_title("HOW TO PLAY",44));var text:=Label.new();text.text="Move with A and D.\nJump with Space.\nKick with J or Left Mouse.\nCharge a kick with K or Right Mouse.\nPress E to read clues or interact.\nPress R to restart the current challenge.\n\nAncient mechanisms respond only to kicks.";text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_theme_font_size_override("font_size",22);text.custom_minimum_size=Vector2(440,390);box.add_child(text);var back:=UIFactory.make_button("Back");back.pressed.connect(_show_home);box.add_child(back)
func _settings()->void:
 var box:=_base_panel();box.add_child(UIFactory.make_title("SETTINGS",44));_add_settings_controls(box);var back:=UIFactory.make_button("Back");back.pressed.connect(_show_home);box.add_child(back)
func _credits()->void:
 var box:=_base_panel();box.add_child(UIFactory.make_title("CREDITS",44));var text:=Label.new();text.text="Game Jam prototype\n\nDesign, code and final art:\nYour three-person team\n\nCurrent visuals:\nOriginal procedural placeholders\n\nNo copyrighted third-party assets are bundled.";text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.add_theme_font_size_override("font_size",21);text.custom_minimum_size=Vector2(440,380);box.add_child(text);var back:=UIFactory.make_button("Back");back.pressed.connect(_show_home);box.add_child(back)
func _add_settings_controls(box:VBoxContainer)->void:
 var music_label:=Label.new();music_label.text="Music Volume";music_label.add_theme_font_size_override("font_size",22);box.add_child(music_label)
 var music:=HSlider.new();music.min_value=0;music.max_value=1;music.step=.01;music.value=AudioManager.music_volume;music.custom_minimum_size=Vector2(410,40);music.value_changed.connect(AudioManager.set_music_volume);box.add_child(music)
 var sfx_label:=Label.new();sfx_label.text="SFX Volume";sfx_label.add_theme_font_size_override("font_size",22);box.add_child(sfx_label)
 var sfx:=HSlider.new();sfx.min_value=0;sfx.max_value=1;sfx.step=.01;sfx.value=AudioManager.sfx_volume;sfx.custom_minimum_size=Vector2(410,40);sfx.value_changed.connect(AudioManager.set_sfx_volume);box.add_child(sfx)
 var full:=CheckButton.new();full.text="Fullscreen";full.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;full.add_theme_font_size_override("font_size",22);full.toggled.connect(AudioManager.set_fullscreen);box.add_child(full)
