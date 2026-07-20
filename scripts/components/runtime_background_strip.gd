class_name RuntimeBackgroundStrip
extends RefCounted


static func add_to_level(
	level: Node2D,
	texture_paths: Array[String],
	panel_size: Vector2 = Vector2(1920.0, 1080.0),
	panel_y: float = 540.0,
	z_value: int = -40
) -> void:
	if level == null:
		return

	for index in range(texture_paths.size()):
		var path: String = texture_paths[index]

		if not ResourceLoader.exists(path, "Texture2D"):
			push_warning("Missing level background: " + path)
			continue

		var texture := ResourceLoader.load(
			path,
			"Texture2D"
		) as Texture2D

		if texture == null:
			push_warning("Unable to load level background: " + path)
			continue

		var sprite := Sprite2D.new()
		sprite.name = "RuntimeBackground%02d" % (index + 1)
		sprite.texture = texture
		sprite.centered = true
		sprite.position = Vector2(
			panel_size.x * 0.5 + panel_size.x * float(index),
			panel_y
		)
		sprite.z_index = z_value
		sprite.z_as_relative = false

		level.add_child(sprite)
