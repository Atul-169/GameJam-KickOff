class_name WardenEchoProjectile
extends ReflectableProjectile

func _ready() -> void:
	super._ready()
	if visual != null and is_instance_valid(visual):
		visual.visible = false
	var echo_visual := AssetRegistry.make_visual(
		"echo_projectile",
		Vector2(42, 42),
		Color("7deaff"),
		"",
	)
	add_child(echo_visual)

func launch(value: Vector2, source: Node) -> void:
	life = 7.0
	super.launch(value, source)
