class_name LevelManager
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/arin.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")

@export var level_id := "level"
@export var level_title := "Level"
@export var music_key := ""
@export var world_width := 4200.0
@export var world_height := 1080.0
@export var checkpoint_position := Vector2(180, 760)
@export var use_default_floor := true

var player: ArinController
var hud: GameHUD
var state_controller: ChallengeStateController
var canvas_modulate: CanvasModulate
var completed := false
var failed := false
var timer_running := false
var uses_timer := false
var time_remaining := 0.0
var initial_timer := 0.0
var temporary_nodes: Array[Node] = []
var restart_blocked := false

func _ready() -> void:
    add_to_group("level_manager")
    Engine.time_scale = 1.0
    get_tree().paused = false
    GameState.begin_level(level_id)
    _create_background()
    _build_world_bounds()
    build_level()
    state_controller = ChallengeStateController.new()
    add_child(state_controller)
    state_controller.freeze()
    player = PLAYER_SCENE.instantiate() as ArinController
    player.position = checkpoint_position
    add_child(player)
    player.set_spawn(checkpoint_position)
    player.set_camera_limits(0, 0, int(world_width), int(world_height))
    player.knocked_out.connect(_on_player_knocked_out)
    hud = HUD_SCENE.instantiate() as GameHUD
    add_child(hud)
    hud.set_world_state(true)
    hud.set_timer(0.0, false)
    AudioManager.play_music(music_key)
    if not EventBus.checkpoint_reached.is_connected(_on_checkpoint):
        EventBus.checkpoint_reached.connect(_on_checkpoint)
    post_ready()

func _exit_tree() -> void:
    if hud != null and is_instance_valid(hud):
        hud.clear_dialogue_queue()
    if EventBus.checkpoint_reached.is_connected(_on_checkpoint):
        EventBus.checkpoint_reached.disconnect(_on_checkpoint)
    Engine.time_scale = 1.0
    get_tree().paused = false

func build_level() -> void:
    push_error("LevelManager.build_level() must be overridden by a level scene.")

func post_ready() -> void:
    return

func get_reflect_target() -> Vector2:
    if player == null:
        return Vector2.ZERO
    return player.global_position + Vector2(float(player.facing) * 600.0, -50.0)

func _process(delta: float) -> void:
    if timer_running and not completed and not failed:
        time_remaining = maxf(time_remaining - delta, 0.0)
        hud.set_timer(time_remaining, true)
        timer_tick(time_remaining)
        if time_remaining <= 0.0:
            timer_running = false
            on_time_expired()

func timer_tick(_value: float) -> void:
    return

func start_kickoff(seconds: float = 0.0) -> void:
    if completed or failed or state_controller.state == GameState.GameMode.ACTIVE:
        return
    state_controller.activate()
    canvas_modulate.color = Color("8d95a1")
    var tween := create_tween()
    tween.tween_property(canvas_modulate, "color", Color.WHITE, 0.45)
    hud.set_world_state(false)
    EventBus.kickoff_started.emit(level_id)
    AudioManager.play_sfx("kickoff_sfx")
    if seconds > 0.0:
        uses_timer = true
        initial_timer = seconds
        time_remaining = seconds
        timer_running = true
        hud.set_timer(time_remaining, true)

func set_objective(text: String) -> void:
    EventBus.objective_changed.emit(text)
    if hud != null:
        hud.set_objective(text)

func add_time(seconds: float) -> void:
    if not timer_running:
        return
    time_remaining += seconds
    EventBus.time_added.emit(seconds)
    hud.show_message("TIME EXTENDED +%d" % int(seconds), 1.5)

func on_time_expired() -> void:
    fail_challenge("time")

func fail_challenge(reason: String) -> void:
    if failed or completed:
        return
    failed = true
    restart_blocked = false
    timer_running = false
    state_controller.fail()
    if hud != null and is_instance_valid(hud):
        hud.clear_dialogue_queue()
    cleanup_temporary()
    if player != null:
        player.lock_input()
    EventBus.challenge_failed.emit(reason)

func grant_sigil(sigil: String) -> bool:
    if sigil.is_empty():
        return false
    var granted := GameState.add_sigil(sigil)
    if granted and hud != null:
        hud.update_stats()
    return granted

func complete_level(sigil: String = "") -> void:
    if completed or failed:
        return
    if not GameState.mark_level_completed(level_id):
        return
    restart_blocked = true
    completed = true
    timer_running = false
    state_controller.complete()
    if not sigil.is_empty():
        grant_sigil(sigil)
    cleanup_temporary()
    if player != null:
        player.play_victory()
    AudioManager.play_sfx("level_complete_sfx")
    EventBus.level_completed.emit(level_id)


func can_restart() -> bool:
    return not completed and not restart_blocked

func set_restart_blocked(value: bool) -> void:
    restart_blocked = value

func restart_in_place() -> bool:
    return false

func _on_player_knocked_out() -> void:
    if not handle_player_knockout():
        fail_challenge("death")

func handle_player_knockout() -> bool:
    return false

func _on_checkpoint(_id: String) -> void:
    if player != null:
        player.set_spawn(player.global_position)

func reset_local_objects() -> void:
    for node: Node in get_tree().get_nodes_in_group("resettable"):
        if is_ancestor_of(node) and node.has_method("reset_state"):
            node.call("reset_state")

func cleanup_temporary() -> void:
    for node: Node in get_tree().get_nodes_in_group("temporary"):
        if is_ancestor_of(node) and is_instance_valid(node):
            node.queue_free()
    temporary_nodes.clear()

func add_floor(
    rect: Rect2, color: Color = Color("3a4757")
) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.collision_layer = CollisionLayers.WORLD
    body.collision_mask = (
        CollisionLayers.PLAYER
        | CollisionLayers.ENEMY
        | CollisionLayers.KICKABLE
        | CollisionLayers.PROJECTILE
    )
    body.position = rect.position + rect.size * 0.5
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    collision.shape = shape
    body.add_child(collision)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
        Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
        Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
        Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
    ])
    visual.color = color
    body.add_child(visual)
    add_child(body)
    return body

func add_wall(
    center: Vector2,
    size: Vector2,
    rotation_value: float = 0.0,
    color: Color = Color("465267")
) -> StaticBody2D:
    var body := add_floor(Rect2(center - size * 0.5, size), color)
    body.rotation = rotation_value
    return body

func add_label(
    text: String,
    position_value: Vector2,
    size: int = 22,
    color: Color = Color.WHITE
) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position_value
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func add_exit(
    position_value: Vector2, size: Vector2 = Vector2(120, 240)
) -> Area2D:
    var area := Area2D.new()
    area.collision_layer = CollisionLayers.EXIT
    area.collision_mask = CollisionLayers.PLAYER
    var shape_node := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    shape_node.shape = shape
    area.add_child(shape_node)
    area.global_position = position_value
    add_child(area)
    return area

func spawn_scene(path: String, position_value: Vector2) -> Node:
    var packed := load(path) as PackedScene
    if packed == null:
        push_error("Unable to load scene: " + path)
        return null
    var node := packed.instantiate()
    # Level call sites use coordinates local to the LevelManager. Assigning the
    # transform before parenting ensures each node's _ready() captures the
    # correct authored start/reset position instead of Vector2.ZERO.
    if node is Node2D:
        (node as Node2D).position = position_value
    add_child(node)
    return node

func _create_background() -> void:
    canvas_modulate = CanvasModulate.new()
    canvas_modulate.color = Color("8d95a1")
    add_child(canvas_modulate)
    var bg := Polygon2D.new()
    bg.polygon = PackedVector2Array([
        Vector2(0, 0),
        Vector2(world_width, 0),
        Vector2(world_width, world_height),
        Vector2(0, world_height),
    ])
    bg.color = Color("101b2b")
    bg.z_index = -30
    add_child(bg)
    for i in 22:
        var pillar := Polygon2D.new()
        var x := float(i) * 240.0
        pillar.polygon = PackedVector2Array([
            Vector2(x, 250),
            Vector2(x + 80, 190),
            Vector2(x + 112, 920),
            Vector2(x + 20, 920),
        ])
        pillar.color = Color(0.10, 0.16, 0.25, 0.55)
        pillar.z_index = -25
        add_child(pillar)

func _build_world_bounds() -> void:
    if use_default_floor:
        add_floor(
            Rect2(0, 900, world_width, world_height - 900.0),
            Color("344250"),
        )
    add_wall(Vector2(-25, world_height * 0.5), Vector2(50, world_height))
    add_wall(
        Vector2(world_width + 25, world_height * 0.5),
        Vector2(50, world_height),
    )
