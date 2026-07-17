class_name MemoryTile
extends Area2D

signal stepped(tile: MemoryTile)

@export var symbol_id := "BALANCE"
var consumed := false
var enabled := true
var plate: Polygon2D

func _ready() -> void:
    collision_layer = CollisionLayers.TRIGGER
    collision_mask = CollisionLayers.PLAYER
    monitoring = true
    body_entered.connect(_entered)
    plate = Polygon2D.new()
    plate.polygon = PackedVector2Array([
        Vector2(-75, -28),
        Vector2(75, -28),
        Vector2(75, 28),
        Vector2(-75, 28),
    ])
    plate.color = Color("514c68")
    add_child(plate)
    var label := Label.new()
    label.text = symbol_id
    label.position = Vector2(-75, -13)
    label.size = Vector2(150, 26)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(label)

func _entered(body: Node) -> void:
    if consumed or not enabled or not body.is_in_group("player"):
        return
    consumed = true
    stepped.emit(self)

func set_enabled(value: bool) -> void:
    enabled = value
    collision_layer = CollisionLayers.TRIGGER if value else 0

func set_preview(value: bool) -> void:
    modulate = Color("f4dc7b") if value else Color("777386")

func conceal() -> void:
    modulate = Color("777386")

func mark_correct() -> void:
    modulate = Color("73e69b")

func mark_wrong() -> void:
    modulate = Color("e46588")

func reset_use() -> void:
    consumed = false
