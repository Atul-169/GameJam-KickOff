class_name HealthComponent
extends Node
signal damaged(amount: int)
signal died
signal health_changed(current: int, maximum: int)
@export var max_health: int = 1
var current_health: int = 1
func _ready() -> void: current_health = maxi(max_health,1)
func setup(value: int) -> void:
 max_health=maxi(value,1);current_health=max_health;health_changed.emit(current_health,max_health)
func damage(amount: int) -> void:
 if amount<=0 or current_health<=0:return
 current_health=maxi(current_health-amount,0);damaged.emit(amount);health_changed.emit(current_health,max_health)
 if current_health==0:died.emit()
func heal(amount: int) -> void:
 current_health=mini(current_health+maxi(amount,0),max_health);health_changed.emit(current_health,max_health)
func reset() -> void: current_health=max_health;health_changed.emit(current_health,max_health)
