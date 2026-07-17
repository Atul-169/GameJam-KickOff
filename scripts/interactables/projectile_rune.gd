class_name ProjectileRune
extends Area2D
signal activated(rune:ProjectileRune)
@export var rune_id:="RUNE"
var is_active:=false
func _ready()->void:
 var shape_node := CollisionShape2D.new()
 var circle := CircleShape2D.new()
 circle.radius = 48.0
 shape_node.shape = circle
 add_child(shape_node)
 collision_layer=CollisionLayers.TRIGGER
 collision_mask=CollisionLayers.PROJECTILE
 monitoring=true
 var disc:=Polygon2D.new()
 var points:=PackedVector2Array()
 for i in 24:
  points.append(Vector2.from_angle(float(i)/24.0*TAU)*44.0)
 disc.polygon=points
 disc.color=Color("5d3b73")
 add_child(disc)
 var label:=Label.new()
 label.text=rune_id
 label.position=Vector2(-55,-12)
 label.size=Vector2(110,24)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 add_child(label)
 add_to_group("resettable")
func receive_projectile(reflected:bool,_source:Node=null)->void:
 if not reflected or is_active:return
 is_active=true
 modulate=Color("9cff9c")
 AudioManager.play_sfx("rune_sfx")
 activated.emit(self)
func reset_state()->void:
 is_active=false
 modulate=Color.WHITE
