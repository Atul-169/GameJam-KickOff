class_name CheckpointComponent
extends Area2D
@export var checkpoint_id: String="checkpoint"
var activated:=false
func _ready()->void:
 collision_layer=0;collision_mask=CollisionLayers.PLAYER;body_entered.connect(_entered)
func _entered(body:Node)->void:
 if activated or not body.is_in_group("player"):return
 activated=true;EventBus.checkpoint_reached.emit(checkpoint_id)
