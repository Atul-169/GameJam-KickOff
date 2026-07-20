class_name PuzzleRune
extends Area2D

signal touched(rune_id: String)

@export var rune_id := "EAR"
@export var caption := "EAR"
@export var accept_orb := true
@export var accept_player_kick := false
@export var accept_reflected_projectiles := true
var solved := false
var active_contacts: Dictionary = {}

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.KICKABLE | CollisionLayers.PROJECTILE
    monitoring = true
    body_entered.connect(_body_entered)
    body_exited.connect(_body_exited)
    area_entered.connect(_area_entered)
    area_exited.connect(_area_exited)
    _build_visual()
    add_to_group("resettable")

func _build_visual() -> void:
    var disc := Polygon2D.new()
    var points := PackedVector2Array()
    for i in 24:
        points.append(Vector2.from_angle(float(i) / 24.0 * TAU) * 48.0)
    disc.polygon = points
    disc.color = Color("635985")
    add_child(disc)
    var label := Label.new()
    label.text = caption
    label.position = Vector2(-65, -13)
    label.size = Vector2(130, 26)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    add_child(label)

func _body_entered(body: Node) -> void:
    if accept_orb and body is EchoOrb:
        _emit_contact_once(body)

func _body_exited(body: Node) -> void:
    active_contacts.erase(body.get_instance_id())

func _area_entered(area: Area2D) -> void:
    if (
        accept_reflected_projectiles
        and area.has_method("is_reflected")
        and bool(area.call("is_reflected"))
    ):
        _emit_contact_once(area)

func _area_exited(area: Area2D) -> void:
    active_contacts.erase(area.get_instance_id())

func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    _charged: bool,
    source: Node
) -> void:
    # Level 2/"Level 3" accessibility option: the player can activate
    # a rune by standing beside it and kicking it directly. The moving
    # Echo Orb remains usable, but it is no longer required.
    if not accept_player_kick or solved:
        return
    if source == null or not source.is_in_group("player"):
        return
    touched.emit(rune_id)

func _emit_contact_once(source: Object) -> void:
    var contact_id := source.get_instance_id()
    if active_contacts.has(contact_id):
        return
    active_contacts[contact_id] = true
    touched.emit(rune_id)

func set_solved(value: bool) -> void:
    solved = value
    modulate = Color("8cff8c") if value else Color.WHITE
    if value:
        _activation_effect()

func _activation_effect() -> void:
    var texture := AssetRegistry.load_texture("rune_activation")
    if texture == null:
        return
    var effect := Sprite2D.new()
    effect.texture = texture
    add_child(effect)
    var tween := create_tween()
    tween.tween_property(effect, "modulate:a", 0.0, 0.45)
    tween.tween_callback(effect.queue_free)

func reset_state() -> void:
    active_contacts.clear()
    set_solved(false)
