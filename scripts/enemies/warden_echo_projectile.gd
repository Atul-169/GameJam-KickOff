class_name WardenEchoProjectile
extends ReflectableProjectile

func launch(value: Vector2, source: Node) -> void:
    life = 7.0
    super.launch(value, source)
