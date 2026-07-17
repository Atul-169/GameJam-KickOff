class_name WeakPlatform
extends AnimatableBody2D
var start_position:=Vector2.ZERO
var dropped:=false
var active:=false
var visual:Node2D
func _ready()->void:
 collision_layer=CollisionLayers.WORLD;collision_mask=CollisionLayers.PLAYER;start_position=position;visual=AssetRegistry.make_visual("weak_platform",Vector2(230,42),Color("9d7658"),"CRACKED");add_child(visual);add_to_group("freezable");add_to_group("resettable")
 var detector:=Area2D.new();detector.collision_layer=0;detector.collision_mask=CollisionLayers.PLAYER;var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=Vector2(210,52);shape.shape=rect;shape.position.y=-25;detector.add_child(shape);add_child(detector);detector.body_entered.connect(_stepped)
func _stepped(body:Node)->void:
 if not active or dropped or not body.is_in_group("player"):return
 dropped=true;visual.modulate=Color("ffb38a");var shake:=create_tween();shake.tween_property(self,"position:x",start_position.x+7,.08);shake.tween_property(self,"position:x",start_position.x-7,.08);shake.tween_property(self,"position:x",start_position.x,.08);await shake.finished;var fall:=create_tween();fall.tween_property(self,"position:y",start_position.y+380,.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);await fall.finished;collision_layer=0
func set_world_active(value:bool)->void:active=value
func reset_state()->void:dropped=false;active=false;position=start_position;collision_layer=CollisionLayers.WORLD;visual.modulate=Color.WHITE
