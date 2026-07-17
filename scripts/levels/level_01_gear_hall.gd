class_name GearHall
extends LevelManager

var gate: ExitGate
var relay: KickTrigger
var relay_used := false

var switch_a: KickTrigger
var switch_b: KickTrigger
var switch_a_active := false
var switch_b_active := false
var shortcut_committed := false
var cracked_route_cost_paid := false

var lift: ShortcutLift
var cracked_route_zone: Area2D


func _init() -> void:
	level_id = "level_01"
	level_title = "Hall of Still Gears"
	music_key = "gear_hall_music"
	world_width = 4500.0
	world_height = 1500.0
	checkpoint_position = Vector2(160, 790)
	use_default_floor = false


func build_level() -> void:
	add_floor(Rect2(0, 900, 1320, 600), Color("344250"))

	# Keep the upper route solid without blocking the lower shortcut tunnel.
	add_floor(Rect2(1600, 900, 1680, 120), Color("344250"))

	add_floor(Rect2(3520, 900, 980, 600), Color("344250"))
	add_floor(Rect2(1100, 1320, 2500, 180), Color("283846"))
	add_wall(Vector2(1080, 1210), Vector2(40, 220), 0.0, Color("283846"))
	add_wall(Vector2(3620, 1210), Vector2(40, 220), 0.0, Color("283846"))

	add_label(
		"THE PATH EXISTS ONLY WHILE THE HEART TURNS.",
		Vector2(150, 180),
		28,
		Color("9acbd3")
	)

	var pedestal := spawn_scene(
		"res://scenes/interactables/kick_trigger.tscn",
		Vector2(520, 810)
	) as KickTrigger
	pedestal.trigger_id = "gear_pedestal"
	pedestal.asset_key = "gear_pedestal"
	pedestal.caption = "GEAR PEDESTAL"
	pedestal.kicked.connect(_kickoff)

	add_floor(Rect2(735, 810, 180, 90), Color("536477"))

	var p1 := spawn_scene(
		"res://scenes/environment/moving_platform.tscn",
		Vector2(1010, 760)
	) as MovingPlatform
	p1.offset = Vector2(650, 0)
	p1.travel_time = 2.7

	var weak := spawn_scene(
		"res://scenes/hazards/weak_platform.tscn",
		Vector2(1460, 875)
	) as WeakPlatform

	# Invisible range directly below the cracked platform.
	# Entering this range from the upper route costs exactly one health.
	cracked_route_zone = Area2D.new()
	cracked_route_zone.name = "CrackedRouteCostZone"
	cracked_route_zone.position = Vector2(1460, 1050)
	cracked_route_zone.collision_layer = 0
	cracked_route_zone.collision_mask = CollisionLayers.PLAYER
	cracked_route_zone.monitoring = true
	cracked_route_zone.monitorable = false
	add_child(cracked_route_zone)

	var cracked_zone_shape := CollisionShape2D.new()
	var cracked_zone_rectangle := RectangleShape2D.new()
	cracked_zone_rectangle.size = Vector2(240, 260)
	cracked_zone_shape.shape = cracked_zone_rectangle
	cracked_route_zone.add_child(cracked_zone_shape)
	cracked_route_zone.body_entered.connect(_cracked_route_entered)

	add_label("WEAK ROUTE", Vector2(1380, 805), 18, Color("d9a37f"))

	spawn_scene(
		"res://scenes/hazards/rotating_gear.tscn",
		Vector2(1850, 795)
	)
	spawn_scene(
		"res://scenes/hazards/rotating_gear.tscn",
		Vector2(2090, 690)
	)

	var p2 := spawn_scene(
		"res://scenes/environment/moving_platform.tscn",
		Vector2(2450, 820)
	) as MovingPlatform
	p2.offset = Vector2(0, -270)
	p2.travel_time = 2.0

	add_wall(Vector2(2700, 770), Vector2(170, 260), 0.0, Color("465267"))

	var rock1 := spawn_scene(
		"res://scenes/hazards/falling_rock.tscn",
		Vector2(2970, 250)
	) as FallingRock
	rock1.fall_distance = 620

	var rock2 := spawn_scene(
		"res://scenes/hazards/falling_rock.tscn",
		Vector2(3210, 220)
	) as FallingRock
	rock2.fall_distance = 650

	relay = spawn_scene(
		"res://scenes/interactables/time_relay.tscn",
		Vector2(3650, 800)
	) as KickTrigger
	relay.kicked.connect(_relay_kicked)

	# Switch A is inside the lower route.
	switch_a = spawn_scene(
		"res://scenes/interactables/kick_switch.tscn",
		Vector2(1800, 1230)
	) as KickTrigger
	switch_a.trigger_id = "switch_A"
	switch_a.caption = "SWITCH A"
	switch_a.active_color = Color("7effb2")
	switch_a.kicked.connect(_switch_a_kicked)

	# The lift is placed before Switch B because B must move with the lift.
	lift = spawn_scene(
		"res://scenes/environment/shortcut_lift.tscn",
		Vector2(3400, 1295)
	) as ShortcutLift
	lift.rise_offset = Vector2(0, -430)

	# Switch B is a child of the lift, so it travels upward with it.
	var switch_scene := load(
        "res://scenes/interactables/kick_switch.tscn"
	) as PackedScene
	switch_b = switch_scene.instantiate() as KickTrigger
	switch_b.position = Vector2(55, -70)
	switch_b.trigger_id = "switch_B"
	switch_b.caption = "SWITCH B"
	switch_b.active_color = Color("7effb2")
	lift.add_child(switch_b)
	switch_b.kicked.connect(_switch_b_kicked)

	# B remains visible but cannot receive kicks until A is activated.
	switch_b.collision_layer = 0
	switch_b.monitorable = false
	switch_b.modulate = Color("666b75")

	gate = spawn_scene(
		"res://scenes/interactables/exit_gate.tscn",
		Vector2(4080, 455)
	) as ExitGate
	gate.configure_height(390.0)

	var exit := add_exit(Vector2(4250, 770), Vector2(150, 260))
	exit.body_entered.connect(_exit_entered)


func post_ready() -> void:
	set_objective("Kick the Gear Pedestal.")
	EventBus.dialogue_requested.emit(
		"ASTRA MAP",
		"The path exists only while the heart turns.",
		2.8
	)


func _kickoff(_charged: bool) -> void:
	start_kickoff(30.0)
	set_objective("Reach the exit before time expires.")


func timer_tick(value: float) -> void:
	if gate != null:
		gate.set_closure(1.0 - value / initial_timer)


func _relay_kicked(_charged: bool) -> void:
	if not timer_running:
		relay.used = false
		relay.modulate = Color.WHITE
		return

	if relay_used:
		return

	relay_used = true
	add_time(10.0)
	relay.modulate = Color("7effb2")


func _cracked_route_entered(body: Node) -> void:
	if cracked_route_cost_paid or body != player:
		return

	# The trigger covers x = 1340..1580 and y = 920..1180.
	# Only entry through its upper half counts, so approaching later from
	# the lower tunnel does not charge health.
	if body.global_position.y > 1020.0:
		return

	cracked_route_cost_paid = true
	call_deferred("_apply_cracked_route_cost")


func _apply_cracked_route_cost() -> void:
	if (
		not is_inside_tree()
		or player == null
		or not is_instance_valid(player)
		or player.knockout_state
	):
		return

	hud.show_message("CRACKED SHORTCUT: -1 HEALTH", 1.5)
	player.health.damage(1)


func _switch_a_kicked(_charged: bool) -> void:
	if state_controller.state != GameState.GameMode.ACTIVE:
		switch_a.used = false
		switch_a.modulate = Color.WHITE
		return

	if switch_a_active:
		return

	switch_a_active = true
	switch_a.modulate = Color("7effb2")

	set_objective("Switch B unlocked. Stand on the lift and kick it.")
	hud.show_message("SWITCH B UNLOCKED", 1.3)

	# Changing Area2D monitoring/layers inside a kick signal is unsafe.
	call_deferred("_unlock_switch_b")


func _unlock_switch_b() -> void:
	if switch_b == null or not is_instance_valid(switch_b):
		return

	switch_b.modulate = Color.WHITE
	switch_b.set_deferred("monitorable", true)
	switch_b.set_deferred("collision_layer", CollisionLayers.TRIGGER)


func _is_player_standing_on_lift() -> bool:
	if (
		lift == null
		or not is_instance_valid(lift)
		or player == null
		or not is_instance_valid(player)
	):
		return false

	# Preferred path: use the lift's boarding Area2D.
	if lift.has_method("is_player_on_lift"):
		return bool(lift.call("is_player_on_lift", player))

	# Safe fallback for an older cached lift script.
	# Player must be horizontally over the platform and just above it.
	var local_player_position := lift.to_local(player.global_position)
	return (
		absf(local_player_position.x) <= 120.0
		and local_player_position.y >= -150.0
		and local_player_position.y <= 10.0
	)


func _switch_b_kicked(_charged: bool) -> void:
	if not switch_a_active:
		switch_b.used = false
		switch_b.modulate = Color("666b75")
		return

	if switch_b_active or shortcut_committed:
		return

	# B only works while Arin is actually standing on the lift.
	# Use a local helper so the level never crashes if an older lift script
	# is still cached or temporarily loaded.
	if not _is_player_standing_on_lift():
		switch_b.used = false
		switch_b.modulate = Color.WHITE
		hud.show_message("STAND ON THE LIFT FIRST", 1.2)
		return

	switch_b_active = true
	switch_b.modulate = Color("7effb2")
	switch_b.set_deferred("monitorable", false)
	switch_b.set_deferred("collision_layer", 0)

	# Damage and lift movement must occur outside the physics kick callback.
	call_deferred("_commit_shortcut")


func _commit_shortcut() -> void:
	if shortcut_committed or not is_inside_tree():
		return

	shortcut_committed = true
	set_objective("Shortcut active. Ride the lift to the upper route.")
	hud.show_message("LIFT ACTIVATED", 1.2)

	# Health was already charged when Arin entered through the cracked path.
	# Switch B now only starts the lift.
	await get_tree().create_timer(0.15).timeout

	if (
		not is_inside_tree()
		or completed
		or failed
		or player == null
		or not is_instance_valid(player)
		or player.knockout_state
	):
		return

	lift.activate()


func _exit_entered(body: Node) -> void:
	if body != player or not timer_running or time_remaining <= 0.0:
		return

	set_restart_blocked(true)
	timer_running = false

	var dialogue_completed := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ASTRA MAP",
				"text": "One motion reclaimed. Three remain.",
				"duration": 2.2,
			},
			{
				"speaker": "ARIN",
				"text": "Niko, hold on. I'm coming.",
				"duration": 2.0,
			},
		],
		true
	)

	if dialogue_completed and is_inside_tree() and not completed:
		complete_level("time")


func on_time_expired() -> void:
	if gate != null:
		gate.set_closure(1.0)
	hud.show_message("TIME EXPIRED", 1.2)
	super.on_time_expired()
