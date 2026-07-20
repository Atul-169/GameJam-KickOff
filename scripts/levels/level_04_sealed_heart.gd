class_name SealedHeart
extends LevelManager

const SYMBOLS: Array[String] = [
	"BALANCE",
	"EYE",
	"EMPTY CIRCLE",
	"MOON",
	"FLAME",
	"SERPENT",
]
const CORRECT_PATH: Array[String] = [
	"BALANCE", "EYE", "EMPTY CIRCLE", "MOON"
]
const MEMORY_LAYOUTS: Array = [
	[
		Vector2(700, 850),
		Vector2(1080, 720),
		Vector2(1480, 850),
		Vector2(1880, 720),
		Vector2(1080, 850),
		Vector2(1480, 700),
	],
	[
		Vector2(700, 850),
		Vector2(1480, 700),
		Vector2(1080, 850),
		Vector2(1880, 720),
		Vector2(1480, 850),
		Vector2(1080, 720),
	],
	[
		Vector2(1080, 850),
		Vector2(1480, 700),
		Vector2(1880, 720),
		Vector2(1480, 850),
		Vector2(700, 850),
		Vector2(1080, 720),
	],
]

var tiles: Array[MemoryTile] = []
var tile_by_symbol: Dictionary = {}
var memory_gong: KickTrigger
var path_index := 0
var path_active := false
var preview_running := false
var preview_generation := 0
var clue_replays_left := 1
var layout_index := 0
var hunter: ShadowHunter

var final_seal: KickTrigger
var keeper: KeeperBoss
var chain_runes: Array[ProjectileRune] = []
var rune_hits := 0
var phase_two_started := false
var traps: Array[KeeperTrap] = []
var broken_trap_ids: Dictionary = {}
var phase_three_started := false
var real_niko_index := -1
var illusions: Array[NikoIllusion] = []
var phase_three_shadows: Array[Node] = []
var truth_loop := false
var truth_generation := 0
var final_window_started := false
var keeper_defeat_started := false

var niko: NikoCharacter
var final_box: FinalBox
var escape_active := false
var escape_start := Vector2(3400, 790)
var escape_exit: Area2D
var escape_hazards: Array[FallingRock] = []
var final_kick_started := false
var ending_triggered := false
var niko_barrier: Node2D
var astra_visual: Node2D
var keeper_silhouette: Node2D
var sigil_sockets: Array[Polygon2D] = []
var sigil_fill_started := false

func _init() -> void:
	level_id = "level_04"
	level_title = "The Sealed Heart"
	music_key = "final_boss_music"
	world_width = 5400.0
	world_height = 1080.0
	checkpoint_position = Vector2(180, 790)

func _exit_tree() -> void:
	preview_generation += 1
	truth_generation += 1
	truth_loop = false
	real_niko_index = -1
	super._exit_tree()

func build_level() -> void:
	add_label(
		"I SPEAK WITHOUT A VOICE. I GUIDE WITHOUT A HAND.",
		Vector2(140, 130),
		24,
		Color("c5b7dc"),
	)
	add_label(
		"FOLLOW BALANCE, THEN TRUTH, AND THE SILENT PATH WILL STAND.",
		Vector2(140, 170),
		22,
		Color("c5b7dc"),
	)
	_build_memory_platforms()
	_build_memory_tiles()
	memory_gong = spawn_scene(
		"res://scenes/interactables/kick_trigger.tscn", Vector2(420, 810)
	) as KickTrigger
	memory_gong.trigger_id = "memory_gong"
	memory_gong.caption = "ENTRANCE GONG"
	memory_gong.emit_interaction = true
	memory_gong.kicked.connect(_memory_kickoff)
	memory_gong.interacted.connect(_replay_clue)

	final_seal = spawn_scene(
		"res://scenes/interactables/kick_trigger.tscn", Vector2(3050, 800)
	) as KickTrigger
	final_seal.trigger_id = "final_seal"
	final_seal.asset_key = "final_seal"
	final_seal.caption = "FINAL KICKOFF SEAL"
	final_seal.visible = false
	final_seal.collision_layer = 0
	final_seal.kicked.connect(_start_keeper)

	niko = spawn_scene(
		"res://scenes/characters/niko.tscn", Vector2(3550, 780)
	) as NikoCharacter
	niko.play_state("trapped")
	niko.modulate = Color("7dd9cf")
	niko.visible = false
	niko_barrier = _make_barrier(Vector2(3550, 745))
	niko_barrier.visible = false
	astra_visual = AssetRegistry.make_visual(
		"astra", Vector2(70, 90), Color("4de3ff"), "ASTRA"
	)
	astra_visual.global_position = Vector2(3260, 620)
	astra_visual.visible = false
	add_child(astra_visual)
	keeper_silhouette = AssetRegistry.make_visual(
		"keeper", Vector2(150, 205), Color("22162d"), "KEEPER"
	)
	keeper_silhouette.global_position = Vector2(4150, 690)
	keeper_silhouette.modulate.a = 0.42
	keeper_silhouette.visible = false
	add_child(keeper_silhouette)
	final_box = spawn_scene(
		"res://scenes/interactables/final_box.tscn", Vector2(4800, 790)
	) as FinalBox
	final_box.set_enabled(false)
	final_box.visible = false
	final_box.sealed.connect(_final_kick)
	_create_sigil_sockets()

func _build_memory_platforms() -> void:
	var elevated_slots: Array[Vector2] = [
		Vector2(1080, 750),
		Vector2(1480, 750),
		Vector2(1880, 750),
	]
	for slot in elevated_slots:
		add_floor(
			Rect2(slot.x - 115.0, slot.y + 34.0, 230.0, 30.0),
			Color("4a4961"),
		)

func _build_memory_tiles() -> void:
	for index in SYMBOLS.size():
		var tile := MemoryTile.new()
		tile.symbol_id = SYMBOLS[index]
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(150, 60)
		shape_node.shape = shape
		tile.add_child(shape_node)
		tile.global_position = MEMORY_LAYOUTS[0][index]
		add_child(tile)
		tile.stepped.connect(_tile_stepped)
		tiles.append(tile)
		tile_by_symbol[tile.symbol_id] = tile

func _make_barrier(position_value: Vector2) -> Node2D:
	var barrier := Node2D.new()
	barrier.global_position = position_value
	var ring := Line2D.new()
	ring.width = 10.0
	ring.default_color = Color(0.25, 0.9, 1.0, 0.78)
	var points := PackedVector2Array()
	for i in 33:
		points.append(Vector2.from_angle(float(i) / 32.0 * TAU) * 105.0)
	ring.points = points
	barrier.add_child(ring)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-70, -95),
		Vector2(70, -95),
		Vector2(90, 95),
		Vector2(-90, 95),
	])
	glow.color = Color(0.1, 0.65, 0.9, 0.14)
	barrier.add_child(glow)
	add_child(barrier)
	return barrier

func _create_sigil_sockets() -> void:
	var colors: Array[Color] = [
		Color("76c7ff"),
		Color("ac91ff"),
		Color("ffb45b"),
		Color("ffe36a"),
	]
	var names: Array[String] = ["TIME", "ECHO", "FORCE", "TRUTH"]
	for i in 4:
		var socket := Polygon2D.new()
		var points := PackedVector2Array()
		for j in 20:
			points.append(Vector2.from_angle(float(j) / 20.0 * TAU) * 24.0)
		socket.polygon = points
		socket.color = colors[i]
		socket.modulate = Color(0.25, 0.25, 0.3, 0.48)
		socket.global_position = Vector2(4560 + float(i) * 95.0, 600)
		socket.visible = false
		socket.set_meta("active_color", colors[i])
		add_child(socket)
		var label := Label.new()
		label.text = names[i]
		label.position = Vector2(-34, 34)
		label.size = Vector2(68, 22)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		socket.add_child(label)
		sigil_sockets.append(socket)

func post_ready() -> void:
	set_objective("Observe the revealed path. Press E near the gong to replay once.")
	_play_memory_preview()

func _play_memory_preview() -> void:
	if preview_running or path_active:
		return
	preview_running = true
	preview_generation += 1
	var token := preview_generation
	memory_gong.collision_layer = 0
	for tile in tiles:
		tile.reset_use()
		tile.set_enabled(false)
		tile.conceal()
	await get_tree().create_timer(0.35).timeout
	for symbol in CORRECT_PATH:
		if token != preview_generation or not is_inside_tree():
			return
		var tile := tile_by_symbol.get(symbol) as MemoryTile
		if tile == null:
			continue
		tile.set_preview(true)
		await get_tree().create_timer(0.72).timeout
		if token != preview_generation or not is_inside_tree():
			return
		tile.conceal()
		await get_tree().create_timer(0.18).timeout
	if token != preview_generation or not is_inside_tree():
		return
	for tile in tiles:
		tile.set_enabled(true)
		tile.reset_use()
	memory_gong.collision_layer = CollisionLayers.TRIGGER
	preview_running = false
	set_objective("Remember the path revealed before the Kickoff.")

func _replay_clue(_source: Node) -> void:
	if path_active or preview_running:
		return
	if clue_replays_left <= 0:
		hud.show_message("THE CLUE HAS ALREADY BEEN REPLAYED", 1.4)
		return
	clue_replays_left -= 1
	_play_memory_preview()

func _memory_kickoff(_charged: bool) -> void:
	if path_active or preview_running:
		if preview_running:
			memory_gong.used = false
		return
	start_kickoff(24.0)
	path_active = true
	path_index = 0
	memory_gong.collision_layer = 0
	for tile in tiles:
		tile.conceal()
		tile.reset_use()
		tile.set_enabled(true)
	set_objective("Remember the path revealed before the Kickoff.")

func _tile_stepped(tile: MemoryTile) -> void:
	if not path_active:
		return
	if (
		path_index < CORRECT_PATH.size()
		and tile.symbol_id == CORRECT_PATH[path_index]
	):
		tile.mark_correct()
		path_index += 1
		if path_index >= CORRECT_PATH.size():
			_path_solved()
	else:
		_wrong_step(tile)

func _wrong_step(tile: MemoryTile) -> void:
	if not path_active:
		return
	path_active = false
	timer_running = false
	GameState.mistakes += 1
	tile.mark_wrong()
	for item in tiles:
		item.set_enabled(false)
	hud.show_message("FALSE STEP — SHADOW HUNTER AWAKENS", 1.7)
	if hunter != null and is_instance_valid(hunter):
		hunter.queue_free()
	hunter = spawn_scene(
		"res://scenes/enemies/shadow_hunter.tscn",
		player.global_position + Vector2(390, 0),
	) as ShadowHunter
	hunter.set_target(player)
	hunter.set_world_active(true)
	hunter.defeated.connect(_hunter_defeated, CONNECT_ONE_SHOT)

func _hunter_defeated(_enemy: EnemyBase) -> void:
	if completed or failed:
		return
	path_index = 0
	layout_index = (layout_index + 1) % MEMORY_LAYOUTS.size()
	_apply_memory_layout(layout_index)
	for tile in tiles:
		tile.reset_use()
		tile.set_enabled(false)
		tile.conceal()
	await _play_recovery_preview()
	if completed or failed or not is_inside_tree():
		return
	for tile in tiles:
		tile.set_enabled(true)
		tile.reset_use()
		tile.conceal()
	path_active = true
	time_remaining = 24.0
	timer_running = true
	set_objective("The symbols moved. Remember the same logical path.")

func _play_recovery_preview() -> void:
	for symbol in CORRECT_PATH:
		var tile := tile_by_symbol.get(symbol) as MemoryTile
		if tile == null:
			continue
		tile.set_preview(true)
		await get_tree().create_timer(0.55).timeout
		tile.conceal()
		await get_tree().create_timer(0.12).timeout

func _apply_memory_layout(index: int) -> void:
	var safe_index := posmod(index, MEMORY_LAYOUTS.size())
	var layout: Array = MEMORY_LAYOUTS[safe_index]
	for tile_index in tiles.size():
		tiles[tile_index].global_position = layout[tile_index]

func _path_solved() -> void:
	if not path_active:
		return
	path_active = false
	timer_running = false
	grant_sigil("truth")
	set_objective("Truth Sigil obtained. Enter the final chamber.")
	for tile in tiles:
		tile.set_enabled(false)
	final_seal.visible = true
	final_seal.collision_layer = CollisionLayers.TRIGGER
	niko.visible = true
	niko_barrier.visible = true
	astra_visual.visible = true
	keeper_silhouette.visible = true
	final_box.visible = true
	for socket in sigil_sockets:
		socket.visible = true
	_reveal_dialogue()

func _reveal_dialogue() -> void:
	var dialogue_completed := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ASTRA MAP",
				"text": "Four motions. Four broken chains.",
				"duration": 2.4,
			},
			{
				"speaker": "ARIN",
				"text": "You were never guiding me to Niko.",
				"duration": 2.4,
			},
			{
				"speaker": "ASTRA MAP",
				"text": "You were opening the way.",
				"duration": 2.3,
			},
			{
				"speaker": "KEEPER",
				"text": "I cannot begin.",
				"duration": 2.0,
			},
			{
				"speaker": "KEEPER",
				"text": "But every first strike gives me motion.",
				"duration": 2.6,
			},
			{
				"speaker": "ARIN",
				"text": "Then this will be your last.",
				"duration": 2.0,
			},
		],
		true,
	)
	if not dialogue_completed or not is_inside_tree():
		return
	set_objective("Kick the Final Kickoff Seal.")

func _start_keeper(_charged: bool) -> void:
	if keeper != null or completed or failed:
		return
	start_kickoff()
	final_seal.visible = false
	final_seal.collision_layer = 0
	if astra_visual != null:
		astra_visual.visible = false
	if keeper_silhouette != null:
		keeper_silhouette.visible = false
	keeper = spawn_scene(
		"res://scenes/enemies/keeper.tscn", Vector2(4150, 790)
	) as KeeperBoss
	keeper.set_target(player)
	keeper.set_phase(1)
	keeper.set_world_active(true)
	keeper.health_changed.connect(_keeper_health)
	keeper.defeated.connect(_keeper_defeated_sequence, CONNECT_ONE_SHOT)
	hud.show_boss(
		"KEEPER OF FIRST MOTION",
		keeper.max_health,
		"PHASE 1 — REFLECT INTO 3 CHAIN RUNES",
	)
	_phase_one_runes()
	set_objective("Reflect the Keeper's projectiles into three chain runes.")

func _phase_one_runes() -> void:
	var data: Array = [
		["CHAIN I", Vector2(3650, 450)],
		["CHAIN II", Vector2(4100, 330)],
		["CHAIN III", Vector2(4550, 450)],
	]
	for entry in data:
		var rune := ProjectileRune.new()
		rune.rune_id = str(entry[0])
		rune.global_position = entry[1]
		add_child(rune)
		rune.activated.connect(_chain_rune)
		chain_runes.append(rune)

func _chain_rune(_rune: ProjectileRune) -> void:
	if phase_two_started:
		return
	rune_hits += 1
	hud.show_message("CHAIN RUNE %d / 3" % rune_hits, 1.0)
	if rune_hits >= 3 and keeper != null and is_instance_valid(keeper):
		keeper.expose_core(true)
		hud.set_boss_phase("CORE EXPOSED — KICK THE CORE")
		set_objective("The core is exposed. Land real kick hitbox contacts.")

func _keeper_health(current: int, maximum: int) -> void:
	hud.update_boss(current, maximum)
	if (
		keeper != null
		and keeper.phase == 1
		and current <= 12
		and not phase_two_started
	):
		_start_phase_two()

func _start_phase_two() -> void:
	if phase_two_started or keeper == null or not is_instance_valid(keeper):
		return
	phase_two_started = true
	keeper.expose_core(false)
	keeper.set_phase(2)
	keeper.set_world_active(true)
	keeper.global_position = Vector2(4050, 790)
	hud.set_boss_phase("PHASE 2 — BAIT CHARGED COPIES INTO 3 TRAPS")
	set_objective("Lure the Keeper beside a trap, use a charged kick, then dodge.")
	for rune in chain_runes:
		if is_instance_valid(rune):
			rune.queue_free()
	chain_runes.clear()
	traps.clear()
	broken_trap_ids.clear()
	for x in [3550.0, 4050.0, 4550.0]:
		var trap := KeeperTrap.new()
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(170, 50)
		shape_node.shape = shape
		trap.add_child(shape_node)
		trap.global_position = Vector2(x, 850)
		add_child(trap)
		trap.broken.connect(_trap_broken)
		traps.append(trap)

func _trap_broken(trap: KeeperTrap) -> void:
	if phase_three_started:
		return
	var instance_id := trap.get_instance_id()
	if broken_trap_ids.has(instance_id):
		return
	broken_trap_ids[instance_id] = true
	hud.show_message(
		"TRAP BROKEN %d / 3" % broken_trap_ids.size(), 1.2
	)
	if broken_trap_ids.size() >= 3:
		_start_phase_three()

func _start_phase_three() -> void:
	if phase_three_started or keeper == null or not is_instance_valid(keeper):
		return
	phase_three_started = true
	keeper.set_phase(3)
	keeper.set_world_active(true)
	niko.visible = false
	niko_barrier.visible = false
	keeper.global_position = Vector2(4200, 790)
	hud.set_boss_phase("PHASE 3 — FALSE FRIEND")
	set_objective("Watch the brief Truth pulse, then kick the real Niko seal.")
	for trap in traps:
		if is_instance_valid(trap):
			trap.queue_free()
	traps.clear()
	var positions: Array[Vector2] = [
		Vector2(3650, 770),
		Vector2(4050, 770),
		Vector2(4450, 770),
	]
	real_niko_index = select_real_niko_index(positions.size())
	for i in positions.size():
		var illusion := NikoIllusion.new()
		illusion.is_real = i == real_niko_index
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(90, 130)
		shape_node.shape = shape
		illusion.add_child(shape_node)
		illusion.global_position = positions[i]
		add_child(illusion)
		illusion.selected.connect(_illusion_selected)
		illusions.append(illusion)
	truth_loop = true
	truth_generation += 1
	_truth_pulses(truth_generation)


func select_real_niko_index(
	count: int, rng: RandomNumberGenerator = null
) -> int:
	if count <= 0:
		return -1
	if rng != null:
		return rng.randi_range(0, count - 1)
	return randi_range(0, count - 1)

func _truth_pulses(token: int) -> void:
	while truth_loop and token == truth_generation and is_inside_tree():
		hud.set_truth_pulse_status("TRUTH PULSE READY")
		await get_tree().create_timer(0.8).timeout
		if not truth_loop or token != truth_generation or not is_inside_tree():
			return
		EventBus.truth_pulse_requested.emit()
		hud.set_truth_pulse_status("TRUTH PULSE ACTIVE")
		for illusion in illusions:
			if is_instance_valid(illusion):
				illusion.truth_pulse()
		await get_tree().create_timer(1.1).timeout
		if not truth_loop or token != truth_generation or not is_inside_tree():
			return
		hud.set_truth_pulse_status("TRUTH PULSE RECHARGING")
		await get_tree().create_timer(3.4).timeout

func _illusion_selected(illusion: NikoIllusion, _charged: bool) -> void:
	if final_window_started or keeper_defeat_started:
		return
	if illusion.is_real:
		_begin_final_exposed_window()
		return
	GameState.mistakes += 1
	keeper.heal_percent(0.10)
	EventBus.dialogue_requested.emit(
		"KEEPER", "A false beginning feeds me.", 2.0
	)
	var shadow := spawn_scene(
		"res://scenes/enemies/shadow_hunter.tscn",
		illusion.global_position + Vector2(100, 0),
	) as ShadowHunter
	shadow.add_to_group("temporary")
	shadow.set_target(player)
	shadow.set_world_active(true)
	phase_three_shadows.append(shadow)

func _begin_final_exposed_window() -> void:
	if final_window_started or keeper == null or not is_instance_valid(keeper):
		return
	final_window_started = true
	truth_loop = false
	truth_generation += 1
	hud.set_truth_pulse_status("")
	for item in illusions:
		if is_instance_valid(item):
			item.queue_free()
	illusions.clear()
	for shadow in phase_three_shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	phase_three_shadows.clear()
	keeper.begin_final_exposure()
	hud.set_boss_phase("FINAL CORE EXPOSED — CHARGED KICK REQUIRED")
	set_objective("Land one valid charged kick on the exposed Keeper core.")

func _keeper_defeated_sequence() -> void:
	if keeper_defeat_started:
		return
	set_restart_blocked(true)
	keeper_defeat_started = true
	truth_loop = false
	truth_generation += 1
	hud.set_truth_pulse_status("")
	hud.set_boss_phase("THE LAST MOTION IS BROKEN")
	if keeper != null and is_instance_valid(keeper):
		keeper.set_world_active(false)
		var tween := create_tween()
		tween.tween_property(keeper, "modulate:a", 0.0, 0.7)
		await tween.finished
		if is_instance_valid(keeper):
			keeper.queue_free()
	hud.hide_boss()
	EventBus.boss_defeated.emit()
	_fill_sigils()

func _fill_sigils() -> void:
	if sigil_fill_started:
		return
	sigil_fill_started = true
	player.lock_input()
	set_objective("The four Sigils are returning to the Final Box.")
	if not GameState.has_all_sigils():
		player.unlock_input()
		set_objective("All four Sigils are required before the Final Box can awaken.")
		push_error("Final Box blocked because one or more Sigils are missing.")
		return
	for socket in sigil_sockets:
		var active_color: Color = socket.get_meta("active_color", Color.WHITE)
		socket.modulate = active_color
		socket.scale = Vector2(0.25, 0.25)
		var tween := create_tween()
		tween.tween_property(socket, "scale", Vector2.ONE, 0.28).set_trans(
			Tween.TRANS_BACK
		).set_ease(Tween.EASE_OUT)
		AudioManager.play_sfx("rune_sfx")
		await get_tree().create_timer(0.35).timeout
		if not is_inside_tree():
			return
	final_box.visible = true
	final_box.set_enabled(true)
	EventBus.dialogue_requested.emit(
		"SYSTEM",
		"The first kick wakes the prison. The final kick chooses what remains.",
		3.2,
	)
	set_objective("Deliver the final charged kick.")
	player.unlock_input()

func _final_kick() -> void:
	if final_kick_started:
		return
	final_kick_started = true
	final_box.set_enabled(false)
	niko_barrier.visible = false
	niko.visible = true
	EventBus.friend_rescued.emit()
	niko.rescue()
	var rescue_dialogue_completed := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "NIKO",
				"text": "You kicked an ancient nightmare back into its box.",
				"duration": 2.6,
			},
		],
		true,
	)
	if rescue_dialogue_completed and is_inside_tree():
		_start_escape()

func _start_escape() -> void:
	if escape_active:
		return
	set_restart_blocked(false)
	escape_active = true
	GameState.escape_checkpoint = true
	player.reset_to_spawn(escape_start)
	player.set_spawn(escape_start)
	niko.global_position = Vector2(3280, 790)
	niko.visible = true
	niko.move_to(Vector2(5100, 790))
	set_objective("Escape the collapsing sanctuary with Niko!")
	uses_timer = true
	time_remaining = 22.0
	initial_timer = 22.0
	timer_running = true
	escape_hazards.clear()
	for x in [3650.0, 4050.0, 4450.0, 4850.0]:
		var rock := spawn_scene(
			"res://scenes/hazards/falling_rock.tscn", Vector2(x, 230)
		) as FallingRock
		rock.fall_distance = 600.0
		rock.warning_time = 0.75
		rock.set_world_active(true)
		escape_hazards.append(rock)
	escape_exit = add_exit(Vector2(5200, 760), Vector2(160, 280))
	escape_exit.body_entered.connect(_escape_reached)

func restart_in_place() -> bool:
	if not escape_active:
		return false
	_reset_escape()
	return true

func on_time_expired() -> void:
	if escape_active:
		_reset_escape()
	else:
		super.on_time_expired()

func handle_player_knockout() -> bool:
	if escape_active:
		_reset_escape()
		return true
	return false

func _reset_escape() -> void:
	if not escape_active:
		return
	if hud != null and is_instance_valid(hud):
		hud.clear_dialogue_queue()
	Engine.time_scale = 1.0
	get_tree().paused = false
	timer_running = false
	state_controller.activate()
	GameState.game_state = GameState.GameMode.ACTIVE
	player.reset_to_spawn(escape_start)
	niko.global_position = Vector2(3280, 790)
	niko.visible = true
	niko.move_to(Vector2(5100, 790))
	for rock in escape_hazards:
		if is_instance_valid(rock):
			rock.reset_state()
			rock.set_world_active(true)
	time_remaining = 22.0
	timer_running = true
	hud.show_message("ESCAPE CHECKPOINT RESTARTED", 1.5)

func _escape_reached(body: Node) -> void:
	if not escape_active or ending_triggered or body != player:
		return
	ending_triggered = true
	escape_active = false
	timer_running = false
	set_restart_blocked(true)
	var ending_dialogue_completed := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ARIN",
				"text": "You chased my football into a cursed forest.",
				"duration": 2.2,
			},
			{
				"speaker": "NIKO",
				"text": "So this is still your fault.",
				"duration": 2.0,
			},
			{
				"speaker": "ARIN",
				"text": "Mostly.",
				"duration": 1.6,
			},
			{
				"speaker": "NIKO",
				"text": "Try not to kick it into another dimension.",
				"duration": 2.2,
			},
			{
				"speaker": "ARIN",
				"text": "No promises.",
				"duration": 1.8,
			},
		],
		true,
	)
	if ending_dialogue_completed and is_inside_tree() and not completed:
		complete_level()

func get_reflect_target() -> Vector2:
	for rune in chain_runes:
		if is_instance_valid(rune) and not rune.is_active:
			return rune.global_position
	if keeper != null and is_instance_valid(keeper):
		return keeper.global_position
	return super.get_reflect_target()
