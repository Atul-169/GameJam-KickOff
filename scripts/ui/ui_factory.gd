class_name UIFactory
extends RefCounted

static func panel_style(
    color: Color = Color(0.035, 0.055, 0.09, 0.94),
    border: Color = Color("4f8e9e")
) -> StyleBox:
    return panel_style_for("panel", color, border)

static func panel_style_for(
    asset_key: String,
    color: Color = Color(0.035, 0.055, 0.09, 0.94),
    border: Color = Color("4f8e9e")
) -> StyleBox:
    var texture := AssetRegistry.load_texture(asset_key)
    if texture != null:
        return _texture_style(texture, 18.0)
    var flat := StyleBoxFlat.new()
    flat.bg_color = color
    flat.border_color = border
    flat.set_border_width_all(2)
    flat.corner_radius_top_left = 12
    flat.corner_radius_top_right = 12
    flat.corner_radius_bottom_left = 12
    flat.corner_radius_bottom_right = 12
    flat.content_margin_left = 24
    flat.content_margin_right = 24
    flat.content_margin_top = 18
    flat.content_margin_bottom = 18
    return flat

static func _texture_style(texture: Texture2D, margin: float) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = texture
    for side in 4:
        style.set_texture_margin(side, margin)
        style.set_content_margin(side, margin)
    return style

static func style_button(button: Button) -> void:
    button.custom_minimum_size = Vector2(330, 58)
    button.add_theme_font_size_override("font_size", 24)
    var normal_texture := AssetRegistry.load_texture("button_normal")
    var hover_texture := AssetRegistry.load_texture("button_hover")
    var pressed_texture := AssetRegistry.load_texture("button_pressed")
    if normal_texture != null:
        button.add_theme_stylebox_override(
            "normal", _texture_style(normal_texture, 14.0)
        )
        button.add_theme_stylebox_override(
            "hover",
            _texture_style(
                hover_texture if hover_texture != null else normal_texture,
                14.0,
            ),
        )
        button.add_theme_stylebox_override(
            "pressed",
            _texture_style(
                pressed_texture if pressed_texture != null else normal_texture,
                14.0,
            ),
        )
        return
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("18324a")
    normal.border_color = Color("4e8ba6")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(8)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("28526d")
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("102438")
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)

static func make_button(text: String) -> Button:
    var button := Button.new()
    button.text = text
    style_button(button)
    return button

static func make_title(text: String, size: int = 54) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("d8f6ff"))
    return label

static func apply_font(root: Control) -> void:
    var font := AssetRegistry.load_font("main_font")
    if font != null:
        root.add_theme_font_override("font", font)
