class_name EchoBreakableWall
extends StaticBody2D

signal broken

var world_active := false
var broken_once := false
var visual_root: Node2D
var collision: CollisionShape2D
var break_tween: Tween

func _ready() -> void:
    collision_layer = CollisionLayers.WORLD
    collision_mask = (
        CollisionLayers.PLAYER
        | CollisionLayers.ENEMY
        | CollisionLayers.KICKABLE
        | CollisionLayers.PROJECTILE
    )
    collision = $CollisionShape2D
    visual_root = AssetRegistry.make_visual(
        "echo_cracked_wall",
        Vector2(100, 390),
        Color("566278"),
        "CRACKED",
    )
    add_child(visual_root)
    add_to_group("resettable")

func set_world_active(active: bool) -> void:
    world_active = active

func receive_warden_charge(_impact_speed: float, _origin: Vector2) -> bool:
    if not world_active or broken_once:
        return false
    broken_once = true
    collision.set_deferred("disabled", true)
    collision_layer = 0
    collision_mask = 0
    broken.emit()
    AudioManager.play_sfx("rock_fall_sfx")
    _break_effect()
    return true

func reset_state() -> void:
    world_active = false
    broken_once = false
    collision.set_deferred("disabled", false)
    collision_layer = CollisionLayers.WORLD
    collision_mask = (
        CollisionLayers.PLAYER
        | CollisionLayers.ENEMY
        | CollisionLayers.KICKABLE
        | CollisionLayers.PROJECTILE
    )
    if break_tween != null and break_tween.is_valid():
        break_tween.kill()
    break_tween = null
    modulate = Color.WHITE
    visible = true

func _add_crack_lines() -> void:
    var cracks := Line2D.new()
    cracks.width = 7.0
    cracks.default_color = Color("c7d4e8")
    cracks.points = PackedVector2Array([
        Vector2(-12, -150),
        Vector2(18, -80),
        Vector2(-22, -25),
        Vector2(20, 35),
        Vector2(-15, 100),
        Vector2(16, 165),
    ])
    add_child(cracks)

func _break_effect() -> void:
    var dust := CPUParticles2D.new()
    dust.amount = 28
    dust.lifetime = 0.75
    dust.one_shot = true
    dust.explosiveness = 0.9
    dust.direction = Vector2.UP
    dust.spread = 80.0
    dust.initial_velocity_min = 80.0
    dust.initial_velocity_max = 230.0
    dust.gravity = Vector2(0, 340)
    dust.color = Color("a7b0c1")
    add_child(dust)
    dust.emitting = true
    break_tween = create_tween()
    break_tween.tween_property(self, "modulate:a", 0.0, 0.32)
    break_tween.tween_callback(func() -> void: visible = false)
