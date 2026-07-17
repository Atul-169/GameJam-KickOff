class_name EchoSealLock
extends Area2D

signal unlocked

var world_active := false
var cooldown := 0.0
var visual_root: Node2D

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.PROJECTILE
    monitoring = true
    monitorable = true
    visual_root = AssetRegistry.make_visual(
        "echo_seal_lock",
        Vector2(100, 100),
        Color("9259d4"),
        "ECHO LOCK",
    )
    add_child(visual_root)
    add_to_group("resettable")
    set_world_active(false)

func _process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)

func set_world_active(active: bool) -> void:
    world_active = active
    monitoring = active
    monitorable = active
    collision_layer = CollisionLayers.TRIGGER if active else 0
    collision_mask = CollisionLayers.PROJECTILE if active else 0
    modulate = Color.WHITE if active else Color(0.55, 0.55, 0.65, 0.75)

func receive_projectile(reflected: bool, _source: Node = null) -> void:
    if not world_active or not reflected or cooldown > 0.0:
        return
    cooldown = 0.35
    unlocked.emit()
    AudioManager.play_sfx("rune_sfx")
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
    tween.tween_property(self, "scale", Vector2.ONE, 0.18)

func reset_state() -> void:
    cooldown = 0.0
    set_world_active(false)
