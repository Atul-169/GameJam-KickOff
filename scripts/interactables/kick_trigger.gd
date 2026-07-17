class_name KickTrigger
extends Area2D

signal kicked(charged: bool)
signal interacted(source: Node)

@export var trigger_id: String = "trigger"
@export var asset_key: String = "kickoff_bell"
@export var caption: String = "KICK"
@export var one_shot: bool = true
@export var visual_size := Vector2(90, 90)
@export var active_color := Color("ffd54f")
@export var emit_interaction: bool = false

var used := false
var visual: Node2D

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.PLAYER_KICK
    monitoring = true
    add_to_group("resettable")
    call_deferred("_build_visual")

func _build_visual() -> void:
    if visual != null and is_instance_valid(visual):
        visual.queue_free()
    visual = AssetRegistry.make_visual(
        asset_key, visual_size, active_color.darkened(0.28), caption
    )
    add_child(visual)

func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if used and one_shot:
        return
    used = true
    modulate = active_color
    AudioManager.play_sfx("rune_sfx")
    kicked.emit(charged)

func interact(source: Node) -> void:
    if emit_interaction:
        interacted.emit(source)
        return
    if source.has_method("play_push_fail"):
        source.call("play_push_fail")
    EventBus.dialogue_requested.emit(
        "ARIN", "It does not respond to hands.", 1.5
    )

func reset_state() -> void:
    used = false
    modulate = Color.WHITE
