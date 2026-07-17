class_name FinalBox
extends Area2D

signal sealed

var enabled := false
var finished := false

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.PLAYER_KICK
    add_child(
        AssetRegistry.make_visual(
            "final_box", Vector2(150, 130), Color("382b55"), "FINAL BOX"
        )
    )
    modulate = Color("68616f")
    add_to_group("resettable")

func set_enabled(value: bool) -> void:
    enabled = value
    modulate = Color.WHITE if value else Color("68616f")

func receive_kick(
    _force: float,
    _damage: int,
    _direction: Vector2,
    charged: bool,
    _source: Node
) -> void:
    if not enabled or finished:
        return
    if not charged:
        EventBus.dialogue_requested.emit(
            "ARIN", "It needs one final charged kick.", 1.7
        )
        return
    finished = true
    AudioManager.play_sfx("charged_kick_sfx")
    sealed.emit()

func reset_state() -> void:
    finished = false
    set_enabled(false)
