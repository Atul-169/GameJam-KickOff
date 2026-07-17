class_name ArcGuardian
extends EnemyBase
var shoot_cooldown:=1.1
func _ready()->void:
 enemy_id="arc_guardian"
 max_health=2
 move_speed=54.0
 asset_key="arc_guardian"
 caption="ARC"
 tint=Color("815cc2")
 super._ready()
func _physics_process(delta: float) -> void:
 if world_active:
  shoot_cooldown = maxf(shoot_cooldown - delta, 0.0)
 super._physics_process(delta)
func think(_delta:float)->void:
 if target==null:return
 var distance:=global_position.distance_to(target.global_position)
 var dx:=target.global_position.x-global_position.x
 if distance<330.0:velocity.x=-signf(dx)*move_speed
 elif distance>560.0:velocity.x=signf(dx)*move_speed
 else:velocity.x=0.0
 if shoot_cooldown<=0.0:
  shoot_cooldown=2.0
  _shoot()
func _shoot()->void:
 modulate=Color("d7b5ff")
 await get_tree().create_timer(.38).timeout
 modulate=Color.WHITE
 if not world_active or target==null:return
 var projectile_scene:=load("res://scenes/enemies/reflectable_projectile.tscn") as PackedScene
 var projectile:=projectile_scene.instantiate() as ReflectableProjectile
 get_parent().add_child(projectile)
 projectile.global_position=global_position+Vector2(0,-55)
 projectile.launch(projectile.global_position.direction_to(target.global_position+Vector2(0,-45))*390.0,self)
