class_name BossCoreHitbox
extends Area2D

var boss: KeeperBoss

func _ready() -> void:
    collision_layer = 0
    collision_mask = CollisionLayers.PLAYER_KICK
    monitoring = true

func set_enabled(value: bool) -> void:
    collision_layer = CollisionLayers.ENEMY if value else 0
    monitoring = value

func receive_kick(
    force: float,
    damage: int,
    direction: Vector2,
    charged: bool,
    source: Node
) -> void:
    if boss != null and is_instance_valid(boss):
        boss.receive_core_kick(force, damage, direction, charged, source)
