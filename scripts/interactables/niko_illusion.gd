class_name NikoIllusion
extends Area2D
signal selected(illusion:NikoIllusion,charged:bool)
@export var is_real:=false
var visual:Node2D
var selectable:=true
func _ready()->void:
 collision_layer=CollisionLayers.TRIGGER
 collision_mask=CollisionLayers.PLAYER_KICK
 visual=AssetRegistry.make_visual("niko_trapped",Vector2(74,112),Color("258e81"),"NIKO")
 add_child(visual)
func receive_kick(_force:float,_damage:int,_direction:Vector2,charged:bool,_source:Node)->void:
 if not selectable:return
 selectable=false;selected.emit(self,charged)
 await get_tree().create_timer(.8).timeout
 if is_inside_tree():selectable=true
func truth_pulse()->void:
 if is_real:
  var wrist:=Polygon2D.new()
  wrist.polygon=PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)])
  wrist.position=Vector2(22,-22)
  wrist.color=Color("ffe66d")
  add_child(wrist)
  var tween:=create_tween()
  tween.tween_property(wrist,"modulate:a",0.0,1.0)
  tween.tween_callback(wrist.queue_free)
 else:
  var tween:=create_tween()
  tween.tween_property(self,"modulate:a",.35,.12)
  tween.tween_property(self,"modulate:a",1.0,.12)
  tween.tween_property(self,"modulate:a",.5,.12)
  tween.tween_property(self,"modulate:a",1.0,.12)
