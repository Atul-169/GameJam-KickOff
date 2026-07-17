class_name StoneGuardian
extends EnemyBase
var winding_up:=false
func _ready()->void:
 enemy_id="stone_guardian"
 max_health=3
 move_speed=88.0
 asset_key="stone_guardian"
 caption="STONE"
 tint=Color("7f8890")
 super._ready()
func think(_delta:float)->void:
 if target==null or winding_up:return
 var dx:=target.global_position.x-global_position.x
 if absf(dx)>86.0:
  velocity.x=signf(dx)*move_speed
 elif attack_cooldown<=0.0:
  _heavy_attack()
 else:
  velocity.x=0.0
func _heavy_attack()->void:
 winding_up=true
 velocity.x=0.0
 attack_cooldown=1.25
 modulate=Color("ffc77d")
 await get_tree().create_timer(.42).timeout
 if dead:return
 modulate=Color.WHITE
 if world_active and target!=null and global_position.distance_to(target.global_position)<105.0:
  target.take_damage(1,global_position.direction_to(target.global_position)*300.0+Vector2(0,-80))
 await get_tree().create_timer(.18).timeout
 winding_up=false
