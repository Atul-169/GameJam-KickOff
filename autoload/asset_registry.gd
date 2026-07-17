extends Node

const ASSET_MANIFEST := "res://resources/asset_manifest.json"
const ANIMATION_MANIFEST := "res://resources/animation_manifest.json"
const MIN_FRAME_COUNT := 1
const MAX_FRAME_COUNT := 64

var manifest: Dictionary = {}
var animations: Dictionary = {}
var warned: Dictionary = {}
var texture_cache: Dictionary = {}
var audio_cache: Dictionary = {}
var font_cache: Dictionary = {}

func _ready() -> void:
	manifest = _read_json(ASSET_MANIFEST)
	animations = _read_json(ANIMATION_MANIFEST)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_warn_once("manifest:" + path, "Missing manifest: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_warn_once("manifest-open:" + path, "Cannot open manifest: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_warn_once("manifest-json:" + path, "Invalid JSON manifest: " + path)
		return {}
	return parsed as Dictionary

func path_for(key: String) -> String:
	return str(manifest.get(key, ""))

func has_asset(key: String, type_hint: String = "") -> bool:
	var path := path_for(key)
	return not path.is_empty() and ResourceLoader.exists(path, type_hint)

func _warn_once(id: String, message: String = "") -> void:
	if warned.has(id):
		return
	warned[id] = true
	push_warning(
		message if not message.is_empty()
		else "Using procedural placeholder for missing asset key: " + id
	)

func load_texture(key: String) -> Texture2D:
	if texture_cache.has(key):
		return texture_cache[key] as Texture2D
	var path := path_for(key)
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		_warn_once(key)
		return null
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	if texture == null:
		_warn_once(key, "Unable to load texture asset key: " + key)
		return null
	texture_cache[key] = texture
	return texture

func load_audio(key: String) -> AudioStream:
	if audio_cache.has(key):
		return audio_cache[key] as AudioStream
	var path := path_for(key)
	if path.is_empty() or not ResourceLoader.exists(path, "AudioStream"):
		_warn_once(key)
		return null
	var stream := ResourceLoader.load(path, "AudioStream") as AudioStream
	if stream == null:
		_warn_once(key, "Unable to load audio asset key: " + key)
		return null
	audio_cache[key] = stream
	return stream

func load_font(key: String) -> Font:
	if font_cache.has(key):
		return font_cache[key] as Font
	var path := path_for(key)
	if path.is_empty() or not ResourceLoader.exists(path, "Font"):
		_warn_once(key)
		return null
	var font := ResourceLoader.load(path, "Font") as Font
	if font == null:
		_warn_once(key, "Unable to load font asset key: " + key)
		return null
	font_cache[key] = font
	return font

func make_visual(
	key: String,
	size: Vector2,
	color: Color,
	caption: String = ""
) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	var texture := load_texture(key)
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		var texture_size := texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			var ratio := minf(size.x / texture_size.x, size.y / texture_size.y)
			sprite.scale = Vector2(ratio, ratio)
		root.add_child(sprite)
		return root
	if key == "astra":
		_build_astra_placeholder(root, size, color, caption)
	else:
		_build_standard_placeholder(root, size, color, caption)
	return root

func _build_astra_placeholder(
	root: Node2D, size: Vector2, color: Color, caption: String
) -> void:
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -size.y * 0.5),
		Vector2(size.x * 0.5, 0),
		Vector2(0, size.y * 0.5),
		Vector2(-size.x * 0.5, 0),
	])
	diamond.color = color
	root.add_child(diamond)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(0, -size.y * 0.28),
		Vector2(size.x * 0.28, 0),
		Vector2(0, size.y * 0.28),
		Vector2(-size.x * 0.28, 0),
	])
	inner.color = color.lightened(0.35)
	root.add_child(inner)
	_add_caption(root, caption, size)

func _build_standard_placeholder(
	root: Node2D, size: Vector2, color: Color, caption: String
) -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-size.x * 0.38, -size.y * 0.45),
		Vector2(size.x * 0.38, -size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.4),
		Vector2(-size.x * 0.5, size.y * 0.4),
	])
	body.color = color
	root.add_child(body)
	var head := Polygon2D.new()
	head.polygon = _circle_points(minf(size.x, size.y) * 0.22, 14)
	head.position.y = -size.y * 0.5
	head.color = color.lightened(0.12)
	root.add_child(head)
	_add_caption(root, caption, size)

func _add_caption(root: Node2D, caption: String, size: Vector2) -> void:
	if caption.is_empty():
		return
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-size.x, -8)
	label.size = Vector2(size.x * 2.0, 24)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(label)

func build_sprite_frames(
	actor: String, tint: Color, size: Vector2
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	var actor_data: Dictionary = animations.get(actor, {})
	if actor_data.is_empty():
		_warn_once(
			"animation:" + actor,
			"Missing animation manifest section for actor: " + actor,
		)
		return frames
	for animation_name: String in actor_data.keys():
		var cfg: Dictionary = actor_data[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(
			animation_name, maxf(float(cfg.get("fps", 8.0)), 0.1)
		)
		frames.set_animation_loop(animation_name, bool(cfg.get("loop", false)))
		var count := clampi(
			int(cfg.get("frames", MIN_FRAME_COUNT)),
			MIN_FRAME_COUNT,
			MAX_FRAME_COUNT,
		)
		var asset_key := str(cfg.get("asset_key", ""))
		var texture := load_texture(asset_key)
		if texture != null and _can_slice_strip(texture, count):
			var image_size := texture.get_size()
			var frame_width := floorf(image_size.x / float(count))
			for index in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(
					frame_width * index,
					0.0,
					frame_width,
					image_size.y,
				)
				frames.add_frame(animation_name, atlas)
		else:
			if texture != null:
				_warn_once(
					"strip:" + actor + ":" + animation_name,
                    "Invalid horizontal sprite strip; using placeholder for "
					+ actor
					+ "/"
					+ animation_name,
				)
			for index in count:
				frames.add_frame(
					animation_name,
					_placeholder_frame(
						actor,
						animation_name,
						index,
						count,
						tint,
						size,
					),
				)
	return frames

func _can_slice_strip(texture: Texture2D, count: int) -> bool:
	var image_size := texture.get_size()
	if count <= 0 or image_size.x < count or image_size.y <= 0.0:
		return false
	return is_equal_approx(fmod(image_size.x, float(count)), 0.0)

func fit_animated_sprite(
	sprite: AnimatedSprite2D, desired_size: Vector2
) -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return
	if sprite.sprite_frames.get_frame_count(sprite.animation) <= 0:
		return
	var texture := sprite.sprite_frames.get_frame_texture(
		sprite.animation, clampi(sprite.frame, 0, sprite.sprite_frames.get_frame_count(sprite.animation) - 1)
	)
	if texture == null:
		return
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var ratio := minf(
		desired_size.x / texture_size.x,
		desired_size.y / texture_size.y,
	)
	sprite.scale = Vector2(ratio, ratio)
	sprite.position.y = desired_size.y * 0.5 - texture_size.y * ratio * 0.5

func _placeholder_frame(
	_actor: String,
	state: String,
	frame: int,
	count: int,
	tint: Color,
	size: Vector2
) -> Texture2D:
	var width := int(maxf(size.x, 48.0))
	var height := int(maxf(size.y, 80.0))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var phase := float(frame) / float(maxi(count, 1)) * TAU
	var bob := int(round(sin(phase) * (3.0 if state in ["run", "idle"] else 1.0)))
	var center_x := width / 2
	var baseline := height - 4
	var body_color := tint
	if state == "hurt":
		body_color = Color("ff6b6b")
	if state == "knockout":
		body_color = tint.darkened(0.35)
	_fill_rect(
		image,
		Rect2i(center_x - 8, baseline - 49 + bob, 16, 30),
		body_color,
	)
	_fill_circle(
		image,
		Vector2i(center_x, baseline - 59 + bob),
		10,
		body_color.lightened(0.16),
	)
	var leg_shift := int(sin(phase) * 8.0) if state == "run" else 0
	if state == "jump":
		leg_shift = 7
	if state == "fall":
		leg_shift = -5
	_draw_thick_line(
		image,
		Vector2i(center_x - 5, baseline - 20 + bob),
		Vector2i(center_x - 11 - leg_shift, baseline + bob),
		4,
		body_color,
	)
	_draw_thick_line(
		image,
		Vector2i(center_x + 5, baseline - 20 + bob),
		Vector2i(center_x + 11 + leg_shift, baseline + bob),
		4,
		body_color,
	)
	# Draw exactly one arm pose. Previously the default arms were drawn
	# first and the victory/push arms were added on top, which looked like
	# two merged character poses.
	if state == "victory":
		_draw_thick_line(
			image,
			Vector2i(center_x - 6, baseline - 43 + bob),
			Vector2i(center_x - 18, baseline - 68 + bob),
			4,
			body_color,
		)
		_draw_thick_line(
			image,
			Vector2i(center_x + 6, baseline - 43 + bob),
			Vector2i(center_x + 18, baseline - 68 + bob),
			4,
			body_color,
		)
	elif state == "push_fail":
		_draw_thick_line(
			image,
			Vector2i(center_x - 6, baseline - 43 + bob),
			Vector2i(center_x + 22, baseline - 49 + bob),
			4,
			body_color,
		)
		_draw_thick_line(
			image,
			Vector2i(center_x + 6, baseline - 43 + bob),
			Vector2i(center_x + 30, baseline - 39 + bob),
			4,
			body_color,
		)
	else:
		var arm := -7 if state in ["kick", "charged_kick"] else 9
		_draw_thick_line(
			image,
			Vector2i(center_x - 7, baseline - 43 + bob),
			Vector2i(center_x - 18, baseline - 30 + arm + bob),
			4,
			body_color,
		)
		_draw_thick_line(
			image,
			Vector2i(center_x + 7, baseline - 43 + bob),
			Vector2i(center_x + 18, baseline - 30 - arm + bob),
			4,
			body_color,
		)

	if state in ["kick", "charged_kick"]:
		_draw_thick_line(
			image,
			Vector2i(center_x + 4, baseline - 20 + bob),
			Vector2i(
				center_x + 28 + (8 if state == "charged_kick" else 0),
				baseline - 25 + bob,
			),
			5,
			body_color,
		)
	return ImageTexture.create_from_image(image)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(rect.position.y, 0), mini(rect.end.y, image.get_height())):
		for x in range(maxi(rect.position.x, 0), mini(rect.end.x, image.get_width())):
			image.set_pixel(x, y, color)

func _fill_circle(
	image: Image, center: Vector2i, radius: int, color: Color
) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if (
				x >= 0
				and y >= 0
				and x < image.get_width()
				and y < image.get_height()
				and Vector2(x - center.x, y - center.y).length() <= radius
			):
				image.set_pixel(x, y, color)

func _draw_thick_line(
	image: Image,
	start: Vector2i,
	end: Vector2i,
	thickness: int,
	color: Color
) -> void:
	var steps := maxi(maxi(abs(end.x - start.x), abs(end.y - start.y)), 1)
	for i in range(steps + 1):
		var point := Vector2(start).lerp(Vector2(end), float(i) / float(steps))
		_fill_circle(
			image,
			Vector2i(roundi(point.x), roundi(point.y)),
			thickness,
			color,
		)

func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		points.append(Vector2.from_angle(float(i) / float(count) * TAU) * radius)
	return points
