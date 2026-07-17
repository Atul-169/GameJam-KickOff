class_name EchoShade
extends EnemyBase
var copy_enabled:=true
var copied_direction:=Vector2.RIGHT
var copied_charged:=false
var waiting_copy:=false
var vulnerability:=false
func _ready()->void:
 enemy_id="echo_shade"
 max_health=3
 move_speed=122.0
 asset_key="echo_shade"
 caption="ECHO"
 tint=Color(0.28,0.62,0.92,.72)
 super._ready()
 var spawn_texture:=AssetRegistry.load_texture("shadow_spawn")
 if spawn_texture!=null:
  var spawn_effect:=Sprite2D.new();spawn_effect.texture=spawn_texture;visual_root.add_child(spawn_effect);var tween:=create_tween();tween.tween_property(spawn_effect,"modulate:a",0.0,.5);tween.tween_callback(spawn_effect.queue_free)
 if not EventBus.player_kicked.is_connected(_on_player_kicked):EventBus.player_kicked.connect(_on_player_kicked)
func _exit_tree()->void:
 if EventBus.player_kicked.is_connected(_on_player_kicked):EventBus.player_kicked.disconnect(_on_player_kicked)
func think(_delta:float)->void:
 if target==null:return
 var dx:=target.global_position.x-global_position.x
 if absf(dx)>185.0:velocity.x=signf(dx)*move_speed
 else:velocity.x=0.0
func _on_player_kicked(charged:bool,_origin:Vector2,direction:Vector2)->void:
 if not world_active or waiting_copy or not copy_enabled:return
 waiting_copy=true
 copied_charged=charged
 copied_direction=direction
 modulate=Color("9be7ff")
 await get_tree().create_timer(.75).timeout
 if dead or not world_active:
  waiting_copy=false
  modulate=Color.WHITE
  return
 modulate=Color.WHITE
 _shadow_kick()
 waiting_copy=false
 if charged:
  vulnerability=true
  modulate=Color("fff59d")
  await get_tree().create_timer(1.0).timeout
  vulnerability=false
  modulate=Color.WHITE
func _shadow_kick()->void:
 if not world_active or dead:return
 var hitbox:=Area2D.new()
 hitbox.collision_layer=CollisionLayers.ENEMY_ATTACK
 hitbox.collision_mask=CollisionLayers.PLAYER|CollisionLayers.KICKABLE|CollisionLayers.TRIGGER
 var shape_node:=CollisionShape2D.new()
 var rect:=RectangleShape2D.new()
 rect.size=Vector2(140,90) if copied_charged else Vector2(100,75)
 shape_node.shape=rect
 hitbox.add_child(shape_node)
 get_parent().add_child(hitbox)
 hitbox.global_position=global_position+copied_direction*72.0+Vector2(0,-40)
 var flash:=Polygon2D.new()
 flash.polygon=PackedVector2Array([Vector2(-50,-25),Vector2(60,0),Vector2(-50,25)])
 flash.color=Color(0.3,0.75,1.0,.6)
 hitbox.add_child(flash)
 await get_tree().physics_frame
 for body:Node in hitbox.get_overlapping_bodies():
  if body is ArinController:body.take_damage(1,copied_direction*220.0)
  elif body is EchoOrb:body.shadow_kick(copied_direction,copied_charged)
 for area:Area2D in hitbox.get_overlapping_areas():
  if area.has_method("receive_kick"):area.call("receive_kick",700.0 if copied_charged else 450.0,1,copied_direction,copied_charged,self)
 await get_tree().create_timer(.12).timeout
 hitbox.queue_free()
func receive_kick(force:float,damage:int,direction:Vector2,charged:bool,source:Node)->void:
 if charged and vulnerability:damage+=1
 super.receive_kick(force,damage,direction,charged,source)
