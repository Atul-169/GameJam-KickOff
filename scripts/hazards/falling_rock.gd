class_name FallingRock
extends Node2D

@export var fall_distance := 520.0
@export var warning_time := 0.7
@export var repeat_delay := 2.0

var active := false
var running := false
var start_position := Vector2.ZERO
var cycle_generation := 0
var rock: Area2D
var warning: Polygon2D

func _ready() -> void:
    start_position = position
    add_to_group("freezable")
    add_to_group("resettable")
    warning = Polygon2D.new()
    warning.polygon = PackedVector2Array([
        Vector2(-38, 0),
        Vector2(38, 0),
        Vector2(28, 18),
        Vector2(-28, 18),
    ])
    warning.color = Color(1.0, 0.25, 0.15, 0.72)
    warning.position = Vector2(0, fall_distance)
    warning.visible = false
    add_child(warning)
    rock = Area2D.new()
    rock.collision_layer = CollisionLayers.HAZARD
    rock.collision_mask = CollisionLayers.PLAYER
    var shape_node := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 34.0
    shape_node.shape = circle
    rock.add_child(shape_node)
    rock.add_child(
        AssetRegistry.make_visual(
            "falling_rock", Vector2(68, 68), Color("796b5b"), "ROCK"
        )
    )
    add_child(rock)
    rock.body_entered.connect(_hit)

func _process(_delta: float) -> void:
    if active and not running:
        _cycle()

func _cycle() -> void:
    running = true
    cycle_generation += 1
    var token := cycle_generation
    warning.position = Vector2(0, fall_distance)
    warning.visible = true
    await get_tree().create_timer(warning_time).timeout
    if not _cycle_valid(token):
        return
    warning.visible = false
    AudioManager.play_sfx("rock_fall_sfx")
    var tween := create_tween()
    tween.tween_property(rock, "position:y", fall_distance, 0.55).set_trans(
        Tween.TRANS_QUAD
    ).set_ease(Tween.EASE_IN)
    await tween.finished
    if not _cycle_valid(token):
        return
    await get_tree().create_timer(repeat_delay).timeout
    if not _cycle_valid(token):
        return
    rock.position = Vector2.ZERO
    running = false

func _cycle_valid(token: int) -> bool:
    if token != cycle_generation or not is_inside_tree() or not active:
        running = false
        warning.visible = false
        return false
    return true

func _hit(body: Node) -> void:
    if active and body.has_method("take_damage"):
        body.call("take_damage", 1, Vector2(0, 220))

func set_world_active(value: bool) -> void:
    active = value
    if not value:
        cycle_generation += 1
        running = false
        warning.visible = false

func reset_state() -> void:
    cycle_generation += 1
    active = false
    running = false
    rock.position = Vector2.ZERO
    warning.visible = false
