class_name FailScreen
extends Control
signal retry_requested
signal main_menu_requested
func setup(reason:String)->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);var shade:=ColorRect.new();shade.color=Color(0.05,0,0,.82);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade);var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",UIFactory.panel_style());panel.set_anchors_preset(Control.PRESET_CENTER);panel.position=Vector2(-300,-260);panel.size=Vector2(600,520);shade.add_child(panel);var box:=VBoxContainer.new();box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",24);panel.add_child(box);box.add_child(UIFactory.make_title("TIME EXPIRED" if reason=="time" else "THE MOTION ENDS HERE",42));var retry:=UIFactory.make_button("Retry");retry.pressed.connect(func()->void:retry_requested.emit());box.add_child(retry);var menu:=UIFactory.make_button("Main Menu");menu.pressed.connect(func()->void:main_menu_requested.emit());box.add_child(menu)
