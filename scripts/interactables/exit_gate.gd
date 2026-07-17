class_name ExitGate
extends StaticBody2D
signal fully_closed
@export var gate_height:=260.0
var open_position:=Vector2.ZERO
var closed_position:=Vector2.ZERO
var closure:=0.0
var visual:Node2D
func _ready()->void:
 collision_layer=CollisionLayers.WORLD;collision_mask=CollisionLayers.PLAYER
 open_position=position;closed_position=position+Vector2(0,gate_height)
 visual=AssetRegistry.make_visual("exit_gate",Vector2(100,gate_height),Color("8b6a4f"),"GATE");visual.position.y=-gate_height*.5;add_child(visual);add_to_group("resettable")
func configure_height(value:float)->void:
 gate_height=maxf(value,80.0)
 var collision:CollisionShape2D=$CollisionShape2D
 var rectangle:=collision.shape as RectangleShape2D
 rectangle.size=Vector2(100.0,gate_height)
 collision.position.y=-gate_height*.5
 if visual!=null and is_instance_valid(visual):visual.queue_free()
 visual=AssetRegistry.make_visual("exit_gate",Vector2(100,gate_height),Color("8b6a4f"),"GATE")
 visual.position.y=-gate_height*.5
 add_child(visual)
 closed_position=open_position+Vector2(0,gate_height)

func set_closure(value:float)->void:
 closed_position = open_position + Vector2(0, gate_height)
 closure=clampf(value,0.0,1.0);position=open_position.lerp(closed_position,closure)
 if closure>=1.0:fully_closed.emit()
func open_gate()->void:
 var tween:=create_tween();tween.tween_method(set_closure,closure,0.0,.55)
func reset_state()->void:set_closure(0.0)
