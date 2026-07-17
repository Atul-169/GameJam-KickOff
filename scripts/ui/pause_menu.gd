class_name PauseMenu
extends Control
signal resumed
signal restart
signal main_menu
var settings:SettingsMenu
var panel:PanelContainer
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);var shade:=ColorRect.new();shade.color=Color(0,0,0,.67);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade);panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",UIFactory.panel_style());panel.set_anchors_preset(Control.PRESET_CENTER);panel.position=Vector2(-260,-320);panel.size=Vector2(520,640);shade.add_child(panel);_build_main()
func _build_main()->void:
 for child in panel.get_children():child.queue_free()
 var box:=VBoxContainer.new();box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",20);panel.add_child(box);box.add_child(UIFactory.make_title("PAUSED",48))
 for data:Array in [["Resume",_resume],["Restart Challenge",_restart],["Settings",_settings],["Main Menu",_menu]]:
  var button:=UIFactory.make_button(data[0]);button.pressed.connect(data[1]);box.add_child(button)
func _resume()->void:resumed.emit()
func _restart()->void:restart.emit()
func _menu()->void:main_menu.emit()
func _settings()->void:
 for child in panel.get_children():child.queue_free()
 settings=SettingsMenu.new();panel.add_child(settings);settings.closed.connect(_build_main)
