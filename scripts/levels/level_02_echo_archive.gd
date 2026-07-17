class_name EchoArchive
extends LevelManager

const WARDEN_SCENE := "res://scenes/enemies/echo_warden.tscn"
const PROJECTILE_SCENE := "res://scenes/enemies/warden_echo_projectile.tscn"
const SHOCKWAVE_SCENE := "res://scenes/hazards/echo_shockwave.tscn"
const WALL_SCENE := "res://scenes/environment/echo_breakable_wall.tscn"
const TIMED_GATE_SCENE := "res://scenes/interactables/echo_timed_gate.tscn"
const ECHO_LOCK_SCENE := "res://scenes/interactables/echo_seal_lock.tscn"
const RESONANCE_SCENE := "res://scenes/interactables/resonance_strike.tscn"

const INITIAL_ORB_PEDESTAL := Vector2(520, 790)
const EYE_ORB_PEDESTAL := Vector2(3970, 410)
const MOUTH_ORB_PEDESTAL := Vector2(4680, 800)
const ORDER: Array[String] = ["EAR", "EYE", "MOUTH"]

var orb: EchoOrb
var runes: Dictionary = {}
var statues: Dictionary = {}
var sequence := EchoSequenceTracker.new()
var progress := 0
var runes_complete := false
var warden_defeated := false
var completion_dialogue_started := false
var door: ExitGate
var cracked_wall: EchoBreakableWall
var timed_gate: EchoTimedGate
var echo_lock: EchoSealLock
var warden: EchoWarden
var resonance_generation := 0

@onready var ear_marker: Node2D = $RuneMarkers/EAR
@onready var eye_marker: Node2D = $RuneMarkers/EYE
@onready var mouth_marker: Node2D = $RuneMarkers/MOUTH

func _init() -> void:
	level_id = "level_02"
	level_title = "Archive of Echoes — The Waking Warden"
	music_key = "echo_archive_music"
	world_width = 6500.0
	world_height = 1080.0
	checkpoint_position = Vector2(180, 820)
	use_default_floor = false
	sequence.configure(ORDER)

func build_level() -> void:
	_build_archive_geometry()
	_build_inscription()
	orb = spawn_scene(
		"res://scenes/interactables/echo_orb.tscn",
		INITIAL_ORB_PEDESTAL,
	) as EchoOrb
	orb.set_reset_bounds(Rect2(-100, 120, world_width + 200, 1050))
	_make_statue_rune("EAR", ear_marker.position, Color("66dcff"))
	_make_statue_rune("EYE", eye_marker.position, Color("b68cff"))
	_make_statue_rune("MOUTH", mouth_marker.position, Color("ff78c8"))

	cracked_wall = spawn_scene(
		WALL_SCENE, Vector2(2990, 705)
	) as EchoBreakableWall
	timed_gate = spawn_scene(
		TIMED_GATE_SCENE, Vector2(5010, 700)
	) as EchoTimedGate
	echo_lock = spawn_scene(
		ECHO_LOCK_SCENE, Vector2(4620, 515)
	) as EchoSealLock
	warden = spawn_scene(
		WARDEN_SCENE, Vector2(1900, 895)
	) as EchoWarden
	warden.configure_arena(Rect2(1100, 430, 4700, 470))

	door = spawn_scene(
		"res://scenes/interactables/exit_gate.tscn", Vector2(6070, 510)
	) as ExitGate
	door.configure_height(390.0)
	door.set_closure(1.0)
	var exit_area := add_exit(Vector2(6320, 790), Vector2(150, 220))
	exit_area.body_entered.connect(_exit_entered)

func post_ready() -> void:
	set_objective("Read the inscription. Awaken what sleeps in the archive.")
	orb.kicked_off.connect(_orb_started)
	cracked_wall.broken.connect(_wall_broken)
	echo_lock.unlocked.connect(_echo_lock_unlocked)
	warden.set_target(player)
	warden.projectile_requested.connect(_warden_projectile_requested)
	warden.shockwave_requested.connect(_warden_shockwave_requested)
	warden.core_health_changed.connect(_warden_core_health_changed)
	warden.core_exposed_changed.connect(_warden_core_exposed_changed)
	warden.defeated.connect(_warden_defeated)
	warden.set_world_active(false)
	cracked_wall.set_world_active(false)
	timed_gate.set_world_active(false)
	echo_lock.set_world_active(false)
	if not EventBus.player_kicked.is_connected(_player_kicked):
		EventBus.player_kicked.connect(_player_kicked)

func _exit_tree() -> void:
	resonance_generation += 1
	if EventBus.player_kicked.is_connected(_player_kicked):
		EventBus.player_kicked.disconnect(_player_kicked)
	super._exit_tree()

func fail_challenge(reason: String) -> void:
	resonance_generation += 1
	_stop_level_combat()
	super.fail_challenge(reason)

func get_reflect_target() -> Vector2:
	if (
		echo_lock != null
		and is_instance_valid(echo_lock)
		and not runes_complete
		and warden.awakening >= EchoWarden.Awakening.VISION
	):
		return echo_lock.global_position
	if warden != null and is_instance_valid(warden):
		return warden.global_position + Vector2(0, -95)
	return super.get_reflect_target()

func _build_archive_geometry() -> void:
	add_floor(Rect2(0, 900, world_width, 180), Color("25364a"))
	add_floor(Rect2(260, 825, 620, 36), Color("354d68"))
	add_floor(Rect2(980, 770, 560, 34), Color("354d68"))
	add_floor(Rect2(1540, 835, 760, 34), Color("354d68"))
	add_floor(Rect2(3050, 810, 310, 32), Color("425773"))
	add_floor(Rect2(3310, 720, 330, 32), Color("425773"))
	add_floor(Rect2(3570, 630, 340, 32), Color("425773"))
	add_floor(Rect2(3820, 540, 370, 32), Color("425773"))
	add_floor(Rect2(4080, 450, 460, 32), Color("425773"))
	add_floor(Rect2(4480, 835, 440, 34), Color("354d68"))
	add_floor(Rect2(5070, 835, 720, 34), Color("493c63"))
	add_floor(Rect2(5800, 835, 500, 34), Color("354d68"))
	add_wall(Vector2(930, 680), Vector2(300, 30), -0.46, Color("526887"))
	add_wall(Vector2(1280, 520), Vector2(280, 30), 0.42, Color("526887"))
	add_wall(Vector2(4090, 300), Vector2(280, 28), -0.38, Color("625784"))
	add_wall(Vector2(4450, 245), Vector2(260, 28), 0.40, Color("625784"))
	add_wall(Vector2(5320, 755), Vector2(260, 28), -0.46, Color("764d7a"))
	add_wall(Vector2(5710, 570), Vector2(260, 28), 0.48, Color("764d7a"))
	add_wall(Vector2(5000, 405), Vector2(110, 300), 0.0, Color("30263e"))
	add_wall(Vector2(5000, 965), Vector2(110, 130), 0.0, Color("30263e"))
	_add_archive_layering()

func _add_archive_layering() -> void:
	for index in 12:
		var shelf := Polygon2D.new()
		var x := 260.0 + float(index) * 510.0
		shelf.polygon = PackedVector2Array([
			Vector2(x, 230),
			Vector2(x + 220, 230),
			Vector2(x + 190, 760),
			Vector2(x + 25, 760),
		])
		shelf.color = Color(0.14, 0.18, 0.31, 0.65)
		shelf.z_index = -12
		add_child(shelf)
	for index in 7:
		var glow := Line2D.new()
		glow.width = 3.0
		glow.default_color = Color(0.25, 0.82, 1.0, 0.18)
		glow.points = PackedVector2Array([
			Vector2(220 + index * 880, 260),
			Vector2(460 + index * 880, 180),
			Vector2(680 + index * 880, 260),
		])
		glow.z_index = -10
		add_child(glow)

func _build_inscription() -> void:
	var panel := Polygon2D.new()
	panel.polygon = PackedVector2Array([
		Vector2(80, 70),
		Vector2(980, 70),
		Vector2(980, 310),
		Vector2(80, 310),
	])
	panel.color = Color(0.08, 0.12, 0.22, 0.9)
	add_child(panel)
	var inscription := add_label(
        "FIRST, THE SILENT HALL MUST HEAR.\n"
		+ "THEN, THE WATCHER LEARNS TO SEE.\n"
		+ "ONLY AFTER SIGHT RETURNS\n"
		+ "MAY THE SEALED TONGUE SPEAK.\n\n"
		+ "WHEN ALL THREE AWAKEN,\n"
		+ "SILENCE THE HEART THAT ECHOES.",
		Vector2(120, 100),
		24,
		Color("b9ecff"),
	)
	inscription.size = Vector2(820, 190)
	inscription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_statue_rune(id: String, position_value: Vector2, color: Color) -> void:
	var statue := AssetRegistry.make_visual(
		"stone_guardian",
		Vector2(112, 184),
		color.darkened(0.52),
		id,
	)
	statue.position = position_value + Vector2(0, 118)
	add_child(statue)
	statues[id] = statue

	var rune := PuzzleRune.new()
	rune.rune_id = id
	rune.caption = id
	rune.accept_orb = true
	rune.accept_reflected_projectiles = false
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 58.0
	shape_node.shape = shape
	rune.add_child(shape_node)
	rune.position = position_value
	add_child(rune)
	rune.touched.connect(_rune_touched)
	runes[id] = rune

func _orb_started() -> void:
	if completed or failed:
		return
	if state_controller.state != GameState.GameMode.ACTIVE:
		start_kickoff()
		warden.set_world_active(true)
		cracked_wall.set_world_active(true)
		set_objective("Guide the Echo Orb through the waking archive.")
		hud.show_message("THE ARCHIVE STIRS", 1.6)

func _rune_touched(id: String) -> void:
	if (
		completed
		or failed
		or runes_complete
		or state_controller.state != GameState.GameMode.ACTIVE
	):
		return
	if id == "EYE" and not cracked_wall.broken_once:
		_wrong_rune()
		return
	if id == "MOUTH" and not timed_gate.is_open:
		_wrong_rune()
		return
	var result := sequence.register(id)
	progress = sequence.progress
	if result == EchoSequenceTracker.Result.WRONG:
		_wrong_rune()
		return
	if result == EchoSequenceTracker.Result.IGNORED:
		return
	_activate_rune_visual(id)
	AudioManager.play_sfx("rune_sfx")
	match id:
		"EAR":
			_ear_awakened()
		"EYE":
			_eye_awakened()
		"MOUTH":
			_mouth_awakened()

func _ear_awakened() -> void:
	hud.show_message("THE WARDEN HEARS", 1.8)
	set_objective(
        "The Warden hears your steps. Seek what the second verse restores."
	)
	warden.awaken_hearing()
	orb.set_pedestal(EYE_ORB_PEDESTAL)

func _eye_awakened() -> void:
	hud.show_message("THE WARDEN SEES", 1.8)
	set_objective("The Warden sees you now. Complete the final verse.")
	warden.awaken_vision()
	echo_lock.set_world_active(true)
	timed_gate.set_world_active(true)
	orb.set_pedestal(MOUTH_ORB_PEDESTAL)

func _mouth_awakened() -> void:
	runes_complete = true
	progress = ORDER.size()
	hud.show_message("THE WARDEN SPEAKS", 1.8)
	set_objective(
        "The Echo Core is exposed after each scream. "
		+ "Use a charged Resonance Kick."
	)
	timed_gate.open_permanently()
	echo_lock.set_world_active(false)
	orb.set_orb_enabled(false)
	warden.awaken_voice()
	hud.show_boss("ECHO WARDEN", 3, "THE WARDEN SPEAKS")
	hud.update_boss(3, 3)

func _wrong_rune() -> void:
	GameState.mistakes += 1
	sequence.reset()
	progress = 0
	_clear_rune_visuals()
	orb.set_orb_enabled(true)
	orb.set_pedestal(INITIAL_ORB_PEDESTAL)
	if not runes_complete:
		timed_gate.reset_state()
		timed_gate.set_world_active(
			warden.awakening >= EchoWarden.Awakening.VISION
		)
	player.take_damage(1, Vector2(-120.0 * float(player.facing), -60.0))
	warden.enrage(4.5)
	hud.show_message("A FALSE ECHO WAKES ITS ANGER", 2.0)
	set_objective("Interpret the inscription and begin the verse again.")

func _activate_rune_visual(id: String) -> void:
	var rune := runes.get(id) as PuzzleRune
	if rune != null:
		rune.set_solved(true)
	var statue := statues.get(id) as Node2D
	if statue != null:
		statue.modulate = Color("9dffbc")

func _clear_rune_visuals() -> void:
	for rune_value: Variant in runes.values():
		var rune := rune_value as PuzzleRune
		if rune != null:
			rune.set_solved(false)
	for statue_value: Variant in statues.values():
		var statue := statue_value as Node2D
		if statue != null:
			statue.modulate = Color.WHITE

func _wall_broken() -> void:
	hud.show_message("THE UPPER ARCHIVE OPENS", 1.6)
	set_objective("Climb the broken passage and restore the watcher.")

func _echo_lock_unlocked() -> void:
	if runes_complete or warden.awakening < EchoWarden.Awakening.VISION:
		return
	timed_gate.open_temporarily(4.2)
	hud.show_message("ECHO GATE OPEN — 4 SECONDS", 1.5)

func _warden_projectile_requested(origin: Vector2, direction: Vector2) -> void:
	if completed or failed or state_controller.state != GameState.GameMode.ACTIVE:
		return
	var projectile := spawn_scene(PROJECTILE_SCENE, origin) as WardenEchoProjectile
	projectile.launch(direction.normalized() * 440.0, warden)

func _warden_shockwave_requested(origin: Vector2) -> void:
	if completed or failed or not runes_complete:
		return
	var shockwave := spawn_scene(SHOCKWAVE_SCENE, origin) as EchoShockwave
	shockwave.launch()
	hud.set_boss_phase("SCREAM — JUMP, THEN STRIKE THE CORE")

func _warden_core_health_changed(current: int, maximum: int) -> void:
	hud.update_boss(current, maximum)

func _warden_core_exposed_changed(active: bool) -> void:
	if active:
		hud.set_boss_phase("CORE EXPOSED — CHARGED RESONANCE KICK")
	elif runes_complete and not warden_defeated:
		hud.set_boss_phase("AWAIT THE NEXT SCREAM")

func _player_kicked(
	charged: bool, origin: Vector2, direction: Vector2
) -> void:
	if (
		not charged
		or completed
		or failed
		or not runes_complete
		or warden_defeated
		or state_controller.state != GameState.GameMode.ACTIVE
	):
		return
	resonance_generation += 1
	var token := resonance_generation
	var impact_position := origin + direction.normalized() * 108.0
	await get_tree().create_timer(0.35).timeout
	if (
		token != resonance_generation
		or not is_inside_tree()
		or completed
		or failed
		or warden_defeated
	):
		return
	var strike := spawn_scene(RESONANCE_SCENE, impact_position) as ResonanceStrike
	strike.configure(true)

func _warden_defeated() -> void:
	if warden_defeated:
		return
	warden_defeated = true
	resonance_generation += 1
	cleanup_temporary()
	hud.update_boss(0, 3)
	hud.set_boss_phase("THE HEART IS SILENCED")
	door.open_gate()
	EventBus.puzzle_solved.emit("echo_warden")
	_transmission()

func _transmission() -> void:
	if completion_dialogue_started:
		return
	completion_dialogue_started = true
	set_restart_blocked(true)
	var projection := spawn_scene(
		"res://scenes/characters/niko.tscn", Vector2(5850, 730)
	) as NikoCharacter
	projection.modulate = Color(0.3, 1.0, 0.9, 0.65)
	projection.play_state("trapped")
	var dialogue_completed := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "NIKO",
				"text": "Arin… I can hear you.",
				"duration": 2.0,
			},
			{
				"speaker": "ARIN",
				"text": "Niko! Where are you?",
				"duration": 2.0,
			},
			{
				"speaker": "NIKO",
				"text": "Below the last chamber. But the map—",
				"duration": 2.2,
			},
			{
				"speaker": "NIKO",
				"text": "Don't trust everything it shows you.",
				"duration": 2.5,
			},
			{
				"speaker": "ASTRA MAP",
				"text": "SIGNAL LOST.",
				"duration": 1.8,
			},
		],
		true,
	)
	if not dialogue_completed or not is_inside_tree():
		return
	if is_instance_valid(projection):
		projection.queue_free()
	hud.hide_boss()
	set_restart_blocked(false)
	set_objective("Enter the opened archive door.")

func _stop_level_combat() -> void:
	if warden != null and is_instance_valid(warden):
		warden.set_world_active(false)
	if cracked_wall != null and is_instance_valid(cracked_wall):
		cracked_wall.set_world_active(false)
	if timed_gate != null and is_instance_valid(timed_gate):
		timed_gate.set_world_active(false)
	if echo_lock != null and is_instance_valid(echo_lock):
		echo_lock.set_world_active(false)
	cleanup_temporary()

func _exit_entered(body: Node) -> void:
	if body == player and warden_defeated:
		complete_level("echo")
