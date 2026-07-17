class_name KeeperTrap
extends Area2D

signal broken(trap: KeeperTrap)

@export var valid_keeper_distance := 185.0
@export var valid_attack_distance := 155.0
@export var charged_only := true

var broken_once := false
var last_attack_id := -1

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.ENEMY_ATTACK
    add_to_group("resettable")
    var plate := Polygon2D.new()
    plate.polygon = PackedVector2Array([
        Vector2(-85, -20),
        Vector2(85, -20),
        Vector2(72, 20),
        Vector2(-72, 20),
    ])
    plate.color = Color("6f596e")
    add_child(plate)
    var label := Label.new()
    label.text = "CRACKED FLOOR"
    label.position = Vector2(-85, -12)
    label.size = Vector2(170, 24)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(label)

func can_break(
    keeper_position: Vector2,
    attack_center: Vector2,
    charged: bool,
    attack_id: int
) -> bool:
    if broken_once or attack_id == last_attack_id:
        return false
    if charged_only and not charged:
        return false
    if global_position.distance_to(keeper_position) > valid_keeper_distance:
        return false
    return global_position.distance_to(attack_center) <= valid_attack_distance

func try_break(
    keeper_position: Vector2,
    attack_center: Vector2,
    charged: bool,
    attack_id: int
) -> bool:
    if not can_break(keeper_position, attack_center, charged, attack_id):
        return false
    last_attack_id = attack_id
    broken_once = true
    modulate = Color("ffb36c")
    collision_layer = 0
    broken.emit(self)
    return true

func reset_state() -> void:
    broken_once = false
    last_attack_id = -1
    collision_layer = CollisionLayers.TRIGGER
    modulate = Color.WHITE
