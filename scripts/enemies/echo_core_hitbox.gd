class_name EchoCoreHitbox
extends Area2D

var warden: Node

func _ready() -> void:
    collision_layer = CollisionLayers.ENEMY
    collision_mask = CollisionLayers.PLAYER_KICK
    monitoring = true
    monitorable = true

func receive_resonance_strike(strike: Node) -> void:
    if warden != null and is_instance_valid(warden):
        warden.receive_core_strike(strike)
