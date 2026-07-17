class_name MovingPlatform
extends AnimatableBody2D
@export var offset:=Vector2(320,0)
@export var travel_time:=2.4
var start_position:=Vector2.ZERO
var world_active:=false
var direction:=1
var progress:=0.0
func _ready()->void:
 collision_layer=CollisionLayers.WORLD;collision_mask=CollisionLayers.PLAYER;start_position=position;add_to_group("freezable");add_to_group("resettable")
 var body:=Polygon2D.new();body.polygon=PackedVector2Array([Vector2(-100,-18),Vector2(100,-18),Vector2(100,18),Vector2(-100,18)]);body.color=Color("6382a3");add_child(body)
func _physics_process(delta:float)->void:
 if not world_active:return
 progress+=delta/travel_time*float(direction)
 if progress>=1.0:progress=1.0;direction=-1
 elif progress<=0.0:progress=0.0;direction=1
 position=start_position+offset*ease(progress,-1.5)
func set_world_active(value:bool)->void:world_active=value
func reset_state()->void:world_active=false;position=start_position;progress=0.0;direction=1
