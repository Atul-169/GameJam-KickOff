class_name ShadowHunter
extends EnemyBase
var dash_cooldown:=.6
func _ready()->void:
 enemy_id="shadow_hunter"
 max_health=2
 move_speed=160.0
 asset_key="shadow_hunter"
 caption="HUNTER"
 tint=Color("253044")
 super._ready()
func _physics_process(delta:float)->void:
 dash_cooldown=maxf(dash_cooldown-delta,0.0)
 super._physics_process(delta)
func think(_delta:float)->void:
 if target==null:return
 var dx:=target.global_position.x-global_position.x
 velocity.x=signf(dx)*(280.0 if dash_cooldown<=0.0 else move_speed)
 if dash_cooldown<=0.0:dash_cooldown=1.4;modulate=Color("6c7d9e");var tween:=create_tween();tween.tween_property(self,"modulate",Color.WHITE,.25)
 if absf(dx)<70.0 and attack_cooldown<=0.0:
  attack_cooldown=.9
  target.take_damage(1,Vector2(signf(dx)*180.0,-70))
