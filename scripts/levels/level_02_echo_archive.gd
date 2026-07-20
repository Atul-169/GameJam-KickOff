class_name EchoArchive
extends LevelManager


# -------------------------------------------------------------------
# SCENE PATHS
# -------------------------------------------------------------------

const ORB_SCENE := "res://scenes/interactables/echo_orb.tscn"
const WARDEN_SCENE := "res://scenes/enemies/echo_warden.tscn"
const PROJECTILE_SCENE := "res://scenes/enemies/warden_echo_projectile.tscn"
const SHOCKWAVE_SCENE := "res://scenes/hazards/echo_shockwave.tscn"
const WALL_SCENE := "res://scenes/environment/echo_breakable_wall.tscn"
const TIMED_GATE_SCENE := "res://scenes/interactables/echo_timed_gate.tscn"
const ECHO_LOCK_SCENE := "res://scenes/interactables/echo_seal_lock.tscn"
const RESONANCE_SCENE := "res://scenes/interactables/resonance_strike.tscn"
const EXIT_GATE_SCENE := "res://scenes/interactables/exit_gate.tscn"
const NIKO_SCENE := "res://scenes/characters/niko.tscn"


# -------------------------------------------------------------------
# RUNTIME POSITIONS
# Change these values to move Level 2 objects.
#
# X increases  -> moves right
# X decreases  -> moves left
# Y increases  -> moves down
# Y decreases  -> moves up
# -------------------------------------------------------------------

const INITIAL_ORB_PEDESTAL := Vector2(520.0, 790.0)
const EYE_ORB_PEDESTAL := Vector2(3970.0, 410.0)
const MOUTH_ORB_PEDESTAL := Vector2(4680.0, 800.0)

const CRACKED_WALL_POSITION := Vector2(2990.0, 705.0)
const TIMED_GATE_POSITION := Vector2(5010.0, 700.0)
const ECHO_LOCK_POSITION := Vector2(4620.0, 515.0)
const WARDEN_POSITION := Vector2(1900.0, 895.0)
const EXIT_GATE_POSITION := Vector2(6070.0, 510.0)
const EXIT_AREA_POSITION := Vector2(6320.0, 790.0)
const NIKO_PROJECTION_POSITION := Vector2(5850.0, 730.0)

const WARDEN_ARENA := Rect2(
	1100.0,
	430.0,
	4700.0,
	470.0
)

const ORDER: Array[String] = [
	"EAR",
	"EYE",
	"MOUTH",
]


var orb: EchoOrb
var runes: Dictionary = {}
var statues: Dictionary = {}
var sequence := EchoSequenceTracker.new()

var progress := 0
var runes_complete := false
var warden_defeated := false
var completion_dialogue_started := false
var archive_started := false
var resonance_generation := 0

var door: ExitGate
var cracked_wall: EchoBreakableWall
var timed_gate: EchoTimedGate
var echo_lock: EchoSealLock
var warden: EchoWarden


@onready var ear_marker: Node2D = $RuneMarkers/EAR
@onready var eye_marker: Node2D = $RuneMarkers/EYE
@onready var mouth_marker: Node2D = $RuneMarkers/MOUTH


func _init() -> void:
	level_id = "level_02"
	level_title = "Archive of Echoes — The Waking Warden"
	music_key = "echo_archive_music"

	world_width = 6500.0
	world_height = 1080.0
	checkpoint_position = Vector2(180.0, 820.0)

	use_default_floor = false
	sequence.configure(ORDER)


func build_level() -> void:
	# Everything below is generated at runtime.
	_build_echo_archive_background()
	_build_archive_geometry()
	_add_archive_layering()
	_build_inscription()

	orb = spawn_scene(
		ORB_SCENE,
		INITIAL_ORB_PEDESTAL
	) as EchoOrb

	if orb == null:
		push_error("Level 2: EchoOrb could not be spawned.")
		return

	orb.set_reset_bounds(
		Rect2(
			-100.0,
			120.0,
			world_width + 200.0,
			1050.0
		)
	)

	# Rune positions remain controlled by the original RuneMarkers.
	_make_statue_rune(
		"EAR",
		ear_marker.position,
		Color("66dcff")
	)

	_make_statue_rune(
		"EYE",
		eye_marker.position,
		Color("b68cff")
	)

	_make_statue_rune(
		"MOUTH",
		mouth_marker.position,
		Color("ff78c8")
	)

	cracked_wall = spawn_scene(
		WALL_SCENE,
		CRACKED_WALL_POSITION
	) as EchoBreakableWall

	timed_gate = spawn_scene(
		TIMED_GATE_SCENE,
		TIMED_GATE_POSITION
	) as EchoTimedGate

	echo_lock = spawn_scene(
		ECHO_LOCK_SCENE,
		ECHO_LOCK_POSITION
	) as EchoSealLock

	warden = spawn_scene(
		WARDEN_SCENE,
		WARDEN_POSITION
	) as EchoWarden

	door = spawn_scene(
		EXIT_GATE_SCENE,
		EXIT_GATE_POSITION
	) as ExitGate

	if (
		cracked_wall == null
		or timed_gate == null
		or echo_lock == null
		or warden == null
		or door == null
	):
		push_error(
			"Level 2: One or more runtime objects could not be spawned."
		)
		return

	warden.configure_arena(WARDEN_ARENA)

	door.configure_height(390.0)

	# Hide the default procedural gate visual and use Level 2 artwork.
	if door.visual != null and is_instance_valid(door.visual):
		door.visual.visible = false

	var archive_gate_visual: Node2D = AssetRegistry.make_visual(
		"echo_archive_exit_gate",
		Vector2(100.0, 390.0),
		Color.WHITE,
		""
	)
	archive_gate_visual.position.y = -195.0
	door.add_child(archive_gate_visual)
	door.set_closure(1.0)

	var exit_area: Area2D = add_exit(
		EXIT_AREA_POSITION,
		Vector2(150.0, 220.0)
	)
	exit_area.body_entered.connect(_exit_entered)


func post_ready() -> void:
	if (
		orb == null
		or cracked_wall == null
		or timed_gate == null
		or echo_lock == null
		or warden == null
		or door == null
	):
		push_error("Level 2: post_ready stopped because runtime setup failed.")
		return

	set_objective(
		"Kick each glowing rune directly. Follow the inscription for the order."
	)

	orb.kicked_off.connect(_orb_started)
	cracked_wall.broken.connect(_wall_broken)
	echo_lock.unlocked.connect(_echo_lock_unlocked)

	warden.set_target(player)
	warden.projectile_requested.connect(
		_warden_projectile_requested
	)
	warden.shockwave_requested.connect(
		_warden_shockwave_requested
	)
	warden.core_health_changed.connect(
		_warden_core_health_changed
	)
	warden.core_exposed_changed.connect(
		_warden_core_exposed_changed
	)
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
		and warden != null
		and is_instance_valid(warden)
		and warden.awakening >= EchoWarden.Awakening.VISION
	):
		return echo_lock.global_position

	if warden != null and is_instance_valid(warden):
		return warden.global_position + Vector2(0.0, -95.0)

	return super.get_reflect_target()


# -------------------------------------------------------------------
# LEVEL GEOMETRY
# Edit the Rect2 and Vector2 values here to move floors and walls.
# Rect2(x, y, width, height)
# -------------------------------------------------------------------

func _build_archive_geometry() -> void:
	_add_textured_floor(
		Rect2(0.0, 900.0, world_width, 180.0)
	)

	_add_textured_floor(Rect2(260.0, 825.0, 620.0, 36.0))
	_add_textured_floor(Rect2(980.0, 770.0, 560.0, 34.0))
	_add_textured_floor(Rect2(1540.0, 835.0, 760.0, 34.0))
	_add_textured_floor(Rect2(3050.0, 810.0, 310.0, 32.0))
	_add_textured_floor(Rect2(3310.0, 720.0, 330.0, 32.0))
	_add_textured_floor(Rect2(3570.0, 630.0, 340.0, 32.0))
	_add_textured_floor(Rect2(3820.0, 540.0, 370.0, 32.0))
	_add_textured_floor(Rect2(4080.0, 450.0, 460.0, 32.0))
	_add_textured_floor(Rect2(4480.0, 835.0, 440.0, 34.0))
	_add_textured_floor(Rect2(5070.0, 835.0, 720.0, 34.0))
	_add_textured_floor(Rect2(5800.0, 835.0, 500.0, 34.0))

	_add_textured_wall(
		Vector2(930.0, 640.0),
		Vector2(300.0, 30.0),
		-0.46
	)

	_add_textured_wall(
		Vector2(1280.0, 520.0),
		Vector2(280.0, 30.0),
		0.42
	)

	_add_textured_wall(
		Vector2(4090.0, 300.0),
		Vector2(280.0, 28.0),
		-0.38
	)

	_add_textured_wall(
		Vector2(4450.0, 245.0),
		Vector2(260.0, 28.0),
		0.40
	)

	_add_textured_wall(
		Vector2(5320.0, 755.0),
		Vector2(260.0, 28.0),
		-0.46
	)

	_add_textured_wall(
		Vector2(5710.0, 570.0),
		Vector2(260.0, 28.0),
		0.48
	)

	_add_textured_wall(
		Vector2(5000.0, 405.0),
		Vector2(110.0, 300.0),
		0.0
	)

	_add_textured_wall(
		Vector2(5000.0, 965.0),
		Vector2(110.0, 130.0),
		0.0
	)


func _add_archive_layering() -> void:
	for index in 7:
		var glow := Line2D.new()
		glow.width = 3.0
		glow.default_color = Color(
			0.25,
			0.82,
			1.0,
			0.12
		)

		glow.points = PackedVector2Array([
			Vector2(
				220.0 + float(index) * 880.0,
				260.0
			),
			Vector2(
				460.0 + float(index) * 880.0,
				180.0
			),
			Vector2(
				680.0 + float(index) * 880.0,
				260.0
			),
		])

		glow.z_index = -10
		add_child(glow)


func _build_inscription() -> void:
	var panel := Polygon2D.new()

	panel.polygon = PackedVector2Array([
		Vector2(80.0, 70.0),
		Vector2(980.0, 70.0),
		Vector2(980.0, 310.0),
		Vector2(80.0, 310.0),
	])

	panel.color = Color(
		0.08,
		0.12,
		0.22,
		0.9
	)

	add_child(panel)

	var inscription: Label = add_label(
		"FIRST, THE SILENT HALL MUST HEAR.\n"
		+ "THEN, THE WATCHER LEARNS TO SEE.\n"
		+ "ONLY AFTER SIGHT RETURNS\n"
		+ "MAY THE SEALED TONGUE SPEAK.\n\n"
		+ "WHEN ALL THREE AWAKEN,\n"
		+ "SILENCE THE HEART THAT ECHOES.",
		Vector2(120.0, 100.0),
		24,
		Color("b9ecff")
	)

	inscription.size = Vector2(820.0, 190.0)
	inscription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _make_statue_rune(
	id: String,
	position_value: Vector2,
	color: Color
) -> void:
	var key := "echo_statue_" + id.to_lower()

	var statue: Node2D = AssetRegistry.make_visual(
		key,
		Vector2(112.0, 184.0),
		color.darkened(0.52),
		""
	)

	statue.position = position_value + Vector2(0.0, 118.0)
	add_child(statue)
	statues[id] = statue

	var rune := PuzzleRune.new()
	rune.rune_id = id
	rune.caption = id
	rune.accept_orb = true
	rune.accept_player_kick = true
	rune.accept_reflected_projectiles = false

	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	# Slightly generous radius so a nearby normal kick connects reliably.
	shape.radius = 72.0

	shape_node.shape = shape
	rune.add_child(shape_node)
	rune.position = position_value
	add_child(rune)

	# Hide procedural rune shapes and labels.
	for child: Node in rune.get_children():
		if child is Polygon2D or child is Label:
			(child as CanvasItem).visible = false

	var rune_visual: Node2D = AssetRegistry.make_visual(
		"echo_rune_" + id.to_lower(),
		Vector2(100.0, 100.0),
		color,
		""
	)

	rune.add_child(rune_visual)
	rune.touched.connect(_rune_touched)
	runes[id] = rune


func _orb_started() -> void:
	if completed or failed:
		return

	# start_kickoff() is only needed when gameplay is not active yet.
	if state_controller.state != GameState.GameMode.ACTIVE:
		start_kickoff()

	# These must activate regardless of the previous game-state value.
	# Previously they were inside the condition above, which could leave
	# the Warden permanently inactive.
	warden.set_world_active(true)
	cracked_wall.set_world_active(true)

	set_objective(
		"Guide the Echo Orb through the waking archive."
	)

	hud.show_message(
		"THE ARCHIVE STIRS",
		1.6
	)

func _begin_archive_challenge() -> void:
	if archive_started or completed or failed:
		return

	archive_started = true

	if state_controller.state != GameState.GameMode.ACTIVE:
		start_kickoff()

	warden.set_world_active(true)
	cracked_wall.set_world_active(true)

	set_objective(
		"Kick each glowing rune directly. Follow the inscription for the order."
	)

	hud.show_message(
		"THE ARCHIVE STIRS",
		1.6
	)


func _rune_touched(id: String) -> void:
	if completed or failed or runes_complete:
		return

	# Directly kicking the first rune starts the same challenge flow as
	# kicking the movable Echo Orb. The Echo Orb is now optional.
	_begin_archive_challenge()

	if state_controller.state != GameState.GameMode.ACTIVE:
		return

	if id == "EYE" and not cracked_wall.broken_once:
		_wrong_rune()
		return

	if id == "MOUTH" and not timed_gate.is_open:
		_wrong_rune()
		return

	var result: EchoSequenceTracker.Result = sequence.register(id)
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
	hud.show_message(
		"THE WARDEN HEARS",
		1.8
	)

	set_objective(
		"Stand clear. The Warden will smash the cracked wall."
	)

	warden.awaken_hearing()

	# The first Hearing charge is scripted toward the cracked wall.
	# Arin no longer needs to cross over the Warden and lure it manually.
	warden.force_charge_at(
		cracked_wall.global_position
	)

	orb.set_pedestal(EYE_ORB_PEDESTAL)


func _eye_awakened() -> void:
	hud.show_message(
		"THE WARDEN SEES",
		1.8
	)

	set_objective(
		"The Warden sees. Reach the final rune and kick it directly."
	)

	warden.awaken_vision()
	echo_lock.set_world_active(true)
	timed_gate.set_world_active(true)
	orb.set_pedestal(MOUTH_ORB_PEDESTAL)


func _mouth_awakened() -> void:
	runes_complete = true
	progress = ORDER.size()

	hud.show_message(
		"THE WARDEN SPEAKS",
		1.8
	)

	set_objective(
		"The Echo Core is exposed after each scream. "
		+ "Use a charged Resonance Kick."
	)

	timed_gate.open_permanently()
	echo_lock.set_world_active(false)
	orb.set_orb_enabled(false)

	warden.awaken_voice()

	hud.show_boss(
		"ECHO WARDEN",
		3,
		"THE WARDEN SPEAKS"
	)

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
			warden.awakening
			>= EchoWarden.Awakening.VISION
		)

	player.take_damage(
		1,
		Vector2(
			-120.0 * float(player.facing),
			-60.0
		)
	)

	warden.enrage(4.5)

	hud.show_message(
		"A FALSE ECHO WAKES ITS ANGER",
		2.0
	)

	set_objective(
		"Interpret the inscription and begin the verse again."
	)


func _activate_rune_visual(id: String) -> void:
	var rune: PuzzleRune = runes.get(id) as PuzzleRune

	if rune != null:
		rune.set_solved(true)

	var statue: Node2D = statues.get(id) as Node2D

	if statue != null:
		statue.modulate = Color("9dffbc")


func _clear_rune_visuals() -> void:
	for rune_value: Variant in runes.values():
		var rune: PuzzleRune = rune_value as PuzzleRune

		if rune != null:
			rune.set_solved(false)

	for statue_value: Variant in statues.values():
		var statue: Node2D = statue_value as Node2D

		if statue != null:
			statue.modulate = Color.WHITE


func _wall_broken() -> void:
	hud.show_message(
		"THE UPPER ARCHIVE OPENS",
		1.6
	)

	set_objective(
		"Climb the broken passage and restore the watcher."
	)


func _echo_lock_unlocked() -> void:
	if (
		runes_complete
		or warden.awakening
		< EchoWarden.Awakening.VISION
	):
		return

	timed_gate.open_temporarily(4.2)

	hud.show_message(
		"ECHO GATE OPEN — 4 SECONDS",
		1.5
	)


func _warden_projectile_requested(
	origin: Vector2,
	direction: Vector2
) -> void:
	if (
		completed
		or failed
		or state_controller.state
		!= GameState.GameMode.ACTIVE
	):
		return

	var projectile: WardenEchoProjectile = spawn_scene(
		PROJECTILE_SCENE,
		origin
	) as WardenEchoProjectile

	if projectile == null:
		push_error("Level 2: Warden projectile could not be spawned.")
		return

	projectile.launch(
		direction.normalized() * 440.0,
		warden
	)


func _warden_shockwave_requested(origin: Vector2) -> void:
	if completed or failed or not runes_complete:
		return

	var shockwave: EchoShockwave = spawn_scene(
		SHOCKWAVE_SCENE,
		origin
	) as EchoShockwave

	if shockwave == null:
		push_error("Level 2: Echo shockwave could not be spawned.")
		return

	shockwave.launch()

	hud.set_boss_phase(
		"SCREAM — JUMP, THEN STRIKE THE CORE"
	)


func _warden_core_health_changed(
	current: int,
	maximum: int
) -> void:
	hud.update_boss(current, maximum)


func _warden_core_exposed_changed(active: bool) -> void:
	if active:
		hud.set_boss_phase(
			"CORE EXPOSED — CHARGED RESONANCE KICK"
		)
	elif runes_complete and not warden_defeated:
		hud.set_boss_phase(
			"AWAIT THE NEXT SCREAM"
		)


func _player_kicked(
	charged: bool,
	origin: Vector2,
	direction: Vector2
) -> void:
	if (
		not charged
		or completed
		or failed
		or not runes_complete
		or warden_defeated
		or state_controller.state
		!= GameState.GameMode.ACTIVE
	):
		return

	resonance_generation += 1
	var token: int = resonance_generation

	var kick_direction := direction.normalized()

	if kick_direction == Vector2.ZERO:
		kick_direction = Vector2.RIGHT

	var impact_position := (
		origin
		+ kick_direction * 108.0
	)

	await get_tree().create_timer(0.35).timeout

	if (
		token != resonance_generation
		or not is_inside_tree()
		or completed
		or failed
		or warden_defeated
	):
		return

	var strike: ResonanceStrike = spawn_scene(
		RESONANCE_SCENE,
		impact_position
	) as ResonanceStrike

	if strike == null:
		push_error("Level 2: ResonanceStrike could not be spawned.")
		return

	strike.configure(true)


func _warden_defeated() -> void:
	if warden_defeated:
		return

	warden_defeated = true
	resonance_generation += 1

	cleanup_temporary()

	hud.update_boss(0, 3)
	hud.set_boss_phase(
		"THE HEART IS SILENCED"
	)

	door.open_gate()
	EventBus.puzzle_solved.emit("echo_warden")

	_transmission()


func _transmission() -> void:
	if completion_dialogue_started:
		return

	completion_dialogue_started = true
	set_restart_blocked(true)

	var projection: NikoCharacter = spawn_scene(
		NIKO_SCENE,
		NIKO_PROJECTION_POSITION
	) as NikoCharacter

	if projection == null:
		push_error("Level 2: Niko projection could not be spawned.")
		set_restart_blocked(false)
		return

	projection.modulate = Color(
		0.3,
		1.0,
		0.9,
		0.65
	)

	projection.play_state("trapped")

	var dialogue_completed: bool = await hud.show_dialogue_sequence(
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
		true
	)

	if not dialogue_completed or not is_inside_tree():
		return

	if is_instance_valid(projection):
		projection.queue_free()

	hud.hide_boss()
	set_restart_blocked(false)
	set_objective(
		"Enter the opened archive door."
	)


func _stop_level_combat() -> void:
	if warden != null and is_instance_valid(warden):
		warden.set_world_active(false)

	if (
		cracked_wall != null
		and is_instance_valid(cracked_wall)
	):
		cracked_wall.set_world_active(false)

	if timed_gate != null and is_instance_valid(timed_gate):
		timed_gate.set_world_active(false)

	if echo_lock != null and is_instance_valid(echo_lock):
		echo_lock.set_world_active(false)

	cleanup_temporary()


func _exit_entered(body: Node) -> void:
	if body == player and warden_defeated:
		complete_level("echo")


func _build_echo_archive_background() -> void:
	var texture_paths: Array[String] = [
		"res://assets/environment/echo_archive/echo_archive_bg_01.png",
		"res://assets/environment/echo_archive/echo_archive_bg_02.png",
		"res://assets/environment/echo_archive/echo_archive_bg_03.png",
		"res://assets/environment/echo_archive/echo_archive_bg_04.png",
	]

	for index in range(texture_paths.size()):
		var path: String = texture_paths[index]

		if not ResourceLoader.exists(path, "Texture2D"):
			push_warning("Missing Echo Archive background: " + path)
			continue

		var texture := ResourceLoader.load(
			path,
			"Texture2D"
		) as Texture2D

		if texture == null:
			push_warning("Unable to load Echo Archive background: " + path)
			continue

		var sprite := Sprite2D.new()
		sprite.name = "EchoArchiveBackground%02d" % (index + 1)
		sprite.texture = texture
		sprite.centered = true
		sprite.position = Vector2(
			960.0 + 1920.0 * float(index),
			540.0
		)

		# The default LevelManager background is at z = -30.
		sprite.z_index = -29
		sprite.z_as_relative = false

		add_child(sprite)

func _add_textured_floor(rect: Rect2) -> StaticBody2D:
	var body: StaticBody2D = add_floor(
		rect,
		Color(0.0, 0.0, 0.0, 0.0)
	)

	var texture: Texture2D = AssetRegistry.load_texture(
		"echo_archive_floor_repeat"
	)

	if texture != null:
		var visual := Sprite2D.new()
		visual.texture = texture
		visual.centered = false
		visual.region_enabled = true
		visual.region_rect = Rect2(
			Vector2.ZERO,
			rect.size
		)
		visual.position = -rect.size * 0.5
		visual.texture_repeat = (
			CanvasItem.TEXTURE_REPEAT_ENABLED
		)
		visual.z_index = -1
		body.add_child(visual)

	var top_texture: Texture2D = AssetRegistry.load_texture(
		"echo_archive_floor_top"
	)

	if top_texture != null and rect.size.x >= 40.0:
		var top_strip := Sprite2D.new()
		top_strip.texture = top_texture
		top_strip.centered = false
		top_strip.region_enabled = true
		top_strip.region_rect = Rect2(
			Vector2.ZERO,
			Vector2(
				rect.size.x,
				minf(40.0, rect.size.y)
			)
		)
		top_strip.position = -rect.size * 0.5
		top_strip.texture_repeat = (
			CanvasItem.TEXTURE_REPEAT_ENABLED
		)
		top_strip.z_index = 0
		body.add_child(top_strip)

	return body


func _add_textured_wall(
	center: Vector2,
	size: Vector2,
	rotation_value: float = 0.0
) -> StaticBody2D:
	var body: StaticBody2D = _add_textured_floor(
		Rect2(
			center - size * 0.5,
			size
		)
	)

	body.rotation = rotation_value
	return body
