class_name PrologueForest
extends LevelManager

enum SequenceState {
	INTRO_START,
	FIELD_ESTABLISHING,
	ARIN_KICKING,
	BALL_TO_FOREST,
	FRIENDS_RUNNING,
	BALL_ON_SEAL,
	NIKO_APPROACHING,
	NIKO_FALLING,
	SEAL_CLOSING,
	ARIN_PUSH_FAIL,
	ASTRA_APPEARING,
	ASTRA_DIALOGUE,
	PLAYER_CONTROL,
	SEAL_OPENING,
	COMPLETED,
}

const GROUND_Y := 900.0
const FOOTBALL_GROUND_Y := GROUND_Y - 23.0
const SEAL_X := 3100.0
const NIKO_FALL_X_OFFSET := 10.0
const BALL_FOREST_X := SEAL_X + NIKO_FALL_X_OFFSET
const BALL_ON_SEAL_Y := FOOTBALL_GROUND_Y - 25.0
var niko: NikoCharacter
var football: Football

const SEAL_CLOSED_TEXTURE: Texture2D = preload(
	"res://assets/prologue/interactables/ancient_seal_closed.png"
)

const SEAL_OPEN_TEXTURE: Texture2D = preload(
	"res://assets/prologue/interactables/ancient_seal_open.png"
)

@onready var seal: AncientSeal = $AncientSeal
@onready var seal_visual: Sprite2D = $AncientSeal/ClosedVisual
@onready var tunnel_point: Marker2D = $AncientSeal/TunnelPoint


var astra_visual: Node2D
var astra_float_tween: Tween

var sequence_state := SequenceState.INTRO_START
var transition_started := false
var cinematic_generation := 0


func _init() -> void:
	level_id = "prologue"
	level_title = "Prologue: The Lost Ball"
	music_key = "forest_music"
	world_width = 3800.0
	checkpoint_position = Vector2(340.0, GROUND_Y)


func build_level() -> void:
	
	seal_visual.texture = SEAL_CLOSED_TEXTURE
	seal_visual.visible = true
	seal_visual.modulate = Color.WHITE
	transition_started = false
	sequence_state = SequenceState.INTRO_START

	#_forest_art()

	football = spawn_scene(
		"res://scenes/interactables/football.tscn",
		Vector2(520.0, FOOTBALL_GROUND_Y)
	) as Football

	niko = spawn_scene(
		"res://scenes/characters/niko.tscn",
		Vector2(850.0, GROUND_Y)
	) as NikoCharacter

	seal.enabled = true
	seal.interaction_enabled = false
	seal.kick_enabled = false

	if not seal.kicked_open.is_connected(_seal_kicked):
		seal.kicked_open.connect(_seal_kicked)


func post_ready() -> void:
	if not EventBus.player_kicked.is_connected(_on_player_kicked_near_seal):
		EventBus.player_kicked.connect(_on_player_kicked_near_seal)

	state_controller.set_state(GameState.GameMode.INTRO)
	state_controller.set_state(GameState.GameMode.INTRO)
	canvas_modulate.color = Color.WHITE
	set_objective("")
	
	

	if hud.has_method("set_state_panel_visible"):
		hud.call("set_state_panel_visible", false)

	hud.set_world_state(false)

	# The cinematic owns every position. Character physics is disabled so
	# gravity, move_and_slide(), and old scripted keyframes cannot lift them.
	player.lock_input()
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(340.0, GROUND_Y)
	player.set_physics_process(false)
	player.sprite.play("idle")

	niko.velocity = Vector2.ZERO
	niko.global_position = Vector2(850.0, GROUND_Y)
	niko.set_physics_process(false)
	niko.play_state("idle")

	football.freeze = true
	football.sleeping = true
	football.linear_velocity = Vector2.ZERO
	football.angular_velocity = 0.0
	football.global_position = Vector2(520.0, FOOTBALL_GROUND_Y)
	football.set_physics_process(false)

	cinematic_generation += 1
	var token := cinematic_generation
	call_deferred("_run_intro_cinematic", token)


func _run_intro_cinematic(token: int) -> void:
	if not _cinematic_valid(token):
		return

	EventBus.cutscene_started.emit()

	# --------------------------------------------------------------
	# SHOT 1: field establishing
	# --------------------------------------------------------------
	sequence_state = SequenceState.FIELD_ESTABLISHING
	_ground_all_visible_characters()

	await get_tree().create_timer(0.8).timeout
	if not _cinematic_valid(token):
		return

	var dialogue_ok := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "NIKO",
				"text": "Pass it here, Arin!",
				"duration": 2.0,
			},
		],
		true
	)
	if not dialogue_ok or not _cinematic_valid(token):
		return

	# --------------------------------------------------------------
	# SHOT 2: Arin kicks; football follows an authored arc
	# --------------------------------------------------------------
	sequence_state = SequenceState.ARIN_KICKING

	# Arin প্রথমে ball-এর কাছে দৌড়ে যাবে।
	player.sprite.play("run")

	var arin_to_ball := create_tween()
	arin_to_ball.tween_property(
		player,
		"global_position",
		Vector2(football.global_position.x - 60.0, GROUND_Y),
		0.55
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await arin_to_ball.finished

	if not _cinematic_valid(token):
		return

	# Ball-এর কাছে পৌঁছানোর পর kick করবে।
	player.global_position = Vector2(
		football.global_position.x - 60.0,
		GROUND_Y
	)
	player.sprite.play("kick")

	await get_tree().create_timer(0.20).timeout

	if not _cinematic_valid(token):
		return
	sequence_state = SequenceState.BALL_TO_FOREST

	var ball_start := football.global_position
	var ball_end := Vector2(
		BALL_FOREST_X,
		BALL_ON_SEAL_Y
	)

	# এই point যত উপরে যাবে, ball তত উঁচু arc করবে।
	var ball_control := Vector2(
		(ball_start.x + ball_end.x) * 0.5,
		FOOTBALL_GROUND_Y - 315.0
	)

	var ball_motion := create_tween().set_parallel(true)

	# একটি continuous curve দিয়ে ball যাবে।
	ball_motion.tween_method(
		_set_ball_arc_progress.bind(
			ball_start,
			ball_control,
			ball_end
		),
		0.0,
		1.0,
		1.80
	).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)

	# একই সময়ে smooth spin করবে।
	ball_motion.tween_property(
		football,
		"rotation",
		football.rotation + TAU * 5.0,
		1.80
	).set_trans(Tween.TRANS_LINEAR)

	await ball_motion.finished

	if not _cinematic_valid(token):
		return

	football.global_position = ball_end
	football.rotation = fmod(football.rotation, TAU)
	if not _cinematic_valid(token):
		return

	# The ball is explicitly grounded when the arc finishes.
	football.global_position.y = BALL_ON_SEAL_Y
	player.sprite.play("idle")

	dialogue_ok = await hud.show_dialogue_sequence(
		[
			{
				"speaker": "NIKO",
				"text": "Too much power, Arin!",
				"duration": 2.0,
			},
			{
				"speaker": "ARIN",
				"text": "I meant to do that.",
				"duration": 1.8,
			},
			{
				"speaker": "NIKO",
				"text": "Of course you did. Come on, let's get it.",
				"duration": 2.5,
			},
		],
		true
	)
	if not dialogue_ok or not _cinematic_valid(token):
		return

	# --------------------------------------------------------------
	# SHOT 3: both run into the forest; all Y values remain grounded
	# --------------------------------------------------------------
	sequence_state = SequenceState.FRIENDS_RUNNING
	player.sprite.play("run")
	niko.play_state("run")

	var forest_run := create_tween().set_parallel(true)
	forest_run.tween_property(
		niko,
		"global_position",
		Vector2(2860.0, GROUND_Y),
		2.40
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	forest_run.tween_property(
		player,
		"global_position",
		Vector2(2640.0, GROUND_Y),
		2.65
	).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)

	
	await forest_run.finished
	if not _cinematic_valid(token):
		return

	player.global_position.y = GROUND_Y
	niko.global_position.y = GROUND_Y
	football.global_position = Vector2(
		BALL_FOREST_X,
		BALL_ON_SEAL_Y
	)

	player.sprite.play("idle")
	niko.play_state("idle")

	# --------------------------------------------------------------
	# SHOT 4: Niko approaches the seal from the ground
	# --------------------------------------------------------------
	sequence_state = SequenceState.BALL_ON_SEAL
	await get_tree().create_timer(0.35).timeout
	if not _cinematic_valid(token):
		return

	sequence_state = SequenceState.NIKO_APPROACHING
	niko.play_state("run")

	var niko_approach := create_tween()
	niko_approach.tween_property(
		niko,
		"global_position",
		Vector2(SEAL_X + NIKO_FALL_X_OFFSET, GROUND_Y),
		0.85
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await niko_approach.finished
	if not _cinematic_valid(token):
		return

	niko.global_position = Vector2(
		SEAL_X + NIKO_FALL_X_OFFSET,
		GROUND_Y
	)
	niko.play_state("idle")

	# --------------------------------------------------------------
	# SHOT 5: Seal opens and Niko falls through the tunnel
	# --------------------------------------------------------------
	sequence_state = SequenceState.NIKO_FALLING

	dialogue_ok = await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ARIN",
				"text": "Niko!",
				"duration": 1.4,
			},
		],
		true
	)

	if not dialogue_ok or not _cinematic_valid(token):
		return

	# Closed seal-এর পরিবর্তে Open seal দেখাবে।
	seal_visual.texture = SEAL_OPEN_TEXTURE

	await get_tree().create_timer(0.25).timeout

	if not _cinematic_valid(token):
		return

	var tunnel_position := tunnel_point.global_position
	var original_niko_scale := niko.scale

	# Niko-কে seal-এর exact horizontal centre-এ বসানো।
	# এরপর শুধু Y position change হবে, তাই fall পুরো vertical হবে।
	niko.global_position.x = tunnel_position.x

	niko.play_state("fall")
	niko.z_index = 51
	niko.modulate = Color.WHITE

	# Niko শুধু vertically tunnel opening-এর কাছে নামবে।
	var move_to_tunnel := create_tween()
	move_to_tunnel.tween_property(
		niko,
		"global_position:y",
		tunnel_position.y,
		0.28
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await move_to_tunnel.finished

	if not _cinematic_valid(token):
		return

	# Tunnel-এর মধ্যে সম্পূর্ণ vertical fall।
	var niko_fall := create_tween()

	niko_fall.tween_property(
		niko,
		"global_position:y",
		tunnel_position.y + 25.0,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	niko_fall.tween_callback(
		func() -> void:
			niko.z_index = 49
	)

	niko_fall.tween_property(
		niko,
		"global_position:y",
		tunnel_position.y + 220.0,
		0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	niko_fall.parallel().tween_property(
		niko,
		"scale",
		original_niko_scale * 0.35,
		0.65
	)

	niko_fall.parallel().tween_property(
		niko,
		"modulate:a",
		0.0,
		0.50
	).set_delay(0.10)

	await niko_fall.finished

	if not _cinematic_valid(token):
		return

	niko.visible = false

	# Niko পড়ে যাওয়ার পর seal আবার বন্ধ হবে।
	sequence_state = SequenceState.SEAL_CLOSING
	seal_visual.texture = SEAL_CLOSED_TEXTURE

	await get_tree().create_timer(0.20).timeout

	# Restart/reset-এর জন্য values স্বাভাবিক করে রাখা।
	niko.scale = original_niko_scale
	niko.modulate = Color.WHITE
	niko.z_index = 0

	football.global_position.y = BALL_ON_SEAL_Y

	# --------------------------------------------------------------
	# SHOT 6: Arin runs to the grounded seal and fails by hand
	# --------------------------------------------------------------
	sequence_state = SequenceState.SEAL_CLOSING
	player.sprite.play("run")

	var arin_to_seal := create_tween()
	arin_to_seal.tween_property(
		player,
		"global_position",
		Vector2(SEAL_X - 80.0, GROUND_Y),
		0.95
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await arin_to_seal.finished
	if not _cinematic_valid(token):
		return

	player.global_position = Vector2(SEAL_X - 80.0, GROUND_Y)
	sequence_state = SequenceState.ARIN_PUSH_FAIL
	player.sprite.play("push_fail")

	dialogue_ok = await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ARIN",
				"text": "It won't move!",
				"duration": 1.8,
			},
		],
		true
	)
	if not dialogue_ok or not _cinematic_valid(token):
		return

	# --------------------------------------------------------------
	# SHOT 7: Astra appears; dialogue advances automatically
	# --------------------------------------------------------------
	sequence_state = SequenceState.ASTRA_APPEARING

	astra_visual = AssetRegistry.make_visual(
		"astra",
		Vector2(90.0, 110.0),
		Color.WHITE,
        ""
	)
	astra_visual.global_position = Vector2(SEAL_X + 125.0, 690.0)
	astra_visual.modulate.a = 0.0
	add_child(astra_visual)

	var astra_appear := create_tween().set_parallel(true)
	astra_appear.tween_property(
		astra_visual,
		"modulate:a",
		1.0,
		0.45
	)
	astra_appear.tween_property(
		astra_visual,
		"global_position:y",
		650.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await astra_appear.finished
	if not _cinematic_valid(token):
		return

	astra_float_tween = create_tween().set_loops()
	astra_float_tween.tween_property(
		astra_visual,
		"global_position:y",
		635.0,
		0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	astra_float_tween.tween_property(
		astra_visual,
		"global_position:y",
		650.0,
		0.75
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	sequence_state = SequenceState.ASTRA_DIALOGUE

	dialogue_ok = await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ASTRA MAP",
				"text": "HANDS COMMAND NOTHING HERE.",
				"duration": 2.3,
			},
			{
				"speaker": "ASTRA MAP",
				"text": "ONLY MOTION AWAKENS THE PATH.",
				"duration": 2.7,
			},
			{
				"speaker": "ARIN",
				"text": "What are you?",
				"duration": 1.8,
			},
			{
				"speaker": "ASTRA MAP",
				"text": "THE PATH BELOW HAS ONE RULE.",
				"duration": 2.5,
			},
			{
				"speaker": "ASTRA MAP",
				"text": "BEGIN WITH A KICK.",
				"duration": 2.2,
			},
		],
		true
	)
	if not dialogue_ok or not _cinematic_valid(token):
		return

# Astra-এর continuous floating animation বন্ধ করা।
	if astra_float_tween != null:
		astra_float_tween.kill()
		astra_float_tween = null

# Instruction শেষ হলে Astra উপরের দিকে উঠে fade হয়ে যাবে।
	if astra_visual != null and is_instance_valid(astra_visual):
		var astra_leave := create_tween().set_parallel(true)

		astra_leave.tween_property(
			astra_visual,
			"modulate:a",
			0.0,
			0.40
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		astra_leave.tween_property(
			astra_visual,
			"global_position:y",
			astra_visual.global_position.y - 45.0,
			0.40
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		await astra_leave.finished

		if astra_visual != null and is_instance_valid(astra_visual):
			astra_visual.queue_free()

		astra_visual = null

	if not _cinematic_valid(token):
		return

	_begin_player_control(token)


func _begin_player_control(token: int) -> void:
	if not _cinematic_valid(token):
		return

	sequence_state = SequenceState.PLAYER_CONTROL

	# Final exact grounded positions before physics resumes.
	player.global_position = Vector2(SEAL_X - 155.0, GROUND_Y)
	player.velocity = Vector2.ZERO
	player.sprite.play("idle")
	player.set_spawn(player.global_position)
	player.set_physics_process(true)

	football.freeze = true
	football.sleeping = true
	football.linear_velocity = Vector2.ZERO
	football.angular_velocity = 0.0
	football.global_position = Vector2(
		BALL_FOREST_X,
		BALL_ON_SEAL_Y
	)

	# The cinematic already performed the failed hand attempt.
	seal.set_enabled(true)
	seal.set_hand_attempted(true)
	seal.set_interaction_enabled(false)
	seal.set_kick_enabled(true)

	print(
		"Seal ready: ",
		"enabled=", seal.enabled,
		", hand_used=", seal.hand_used,
		", kick_enabled=", seal.kick_enabled
	)

	state_controller.set_state(GameState.GameMode.ACTIVE)

	if hud.has_method("set_state_panel_visible"):
		hud.call("set_state_panel_visible", true)

	hud.set_world_state(false)
	set_objective("Kick the Ancient Seal.")

	player.unlock_input()
	EventBus.cutscene_ended.emit()


func _cinematic_valid(token: int) -> bool:
	return (
		token == cinematic_generation
		and is_inside_tree()
		and not completed
		and not failed
		and player != null
		and is_instance_valid(player)
		and niko != null
		and is_instance_valid(niko)
		and football != null
		and is_instance_valid(football)
		and seal != null
		and is_instance_valid(seal)
	)


func _ground_all_visible_characters() -> void:
	if player != null and is_instance_valid(player):
		player.global_position.y = GROUND_Y
		player.velocity.y = 0.0

	if niko != null and is_instance_valid(niko) and niko.visible:
		niko.global_position.y = GROUND_Y
		niko.velocity.y = 0.0

	if football != null and is_instance_valid(football):
		football.global_position.y = FOOTBALL_GROUND_Y
		football.linear_velocity = Vector2.ZERO
		football.angular_velocity = 0.0


func can_kick_seal() -> bool:
	return (
		sequence_state == SequenceState.PLAYER_CONTROL
		and seal != null
		and is_instance_valid(seal)
		and seal.can_receive_kick()
	)


func _seal_kicked() -> void:
	# The signal itself confirms that a valid kick reached the seal.
	if transition_started:
		return

	transition_started = true
	sequence_state = SequenceState.SEAL_OPENING
	call_deferred("_finish_seal_opening")


func _finish_seal_opening() -> void:
	if not is_inside_tree() or completed:
		return

	if seal == null or not is_instance_valid(seal):
		return

	if player == null or not is_instance_valid(player):
		return

	seal.disable_detection_keep_visible()
	set_restart_blocked(true)

	if hud.has_method("set_state_panel_visible"):
		hud.call("set_state_panel_visible", true)

	hud.set_world_state(false)
	set_objective("")

	# Kick করার সঙ্গে সঙ্গে closed seal-এর জায়গায় open seal দেখাবে।
	seal_visual.texture = SEAL_OPEN_TEXTURE
	seal_visual.visible = true
	seal_visual.modulate = Color.WHITE
	seal.modulate = Color.WHITE

	AudioManager.play_sfx("kickoff_sfx")
	hud.show_message("KICKOFF!", 1.2)

	# Kick animation-টা অল্প সময় শেষ হতে দেওয়া।
	player.lock_input()
	player.velocity = Vector2.ZERO

	await get_tree().create_timer(0.18).timeout

	if not is_inside_tree() or completed:
		return

	# Arin-এর normal physics বন্ধ করে cinematic control নেওয়া।
	player.set_cinematic_control(true)
	player.modulate = Color.WHITE
	player.visible = true
	player.z_index = 51

	var tunnel_position := tunnel_point.global_position
	var original_player_scale := player.scale

	# Arin প্রথমে open seal-এর horizontal centre-এ যাবে।
	# শুধু X change হবে, তাই diagonally নিচে যাবে না।
	player.play_cinematic_animation("run")

	var move_to_seal := create_tween()
	move_to_seal.tween_property(
		player,
		"global_position:x",
		tunnel_position.x,
		0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await move_to_seal.finished

	if not is_inside_tree() or completed:
		return

	# Fall শুরু হওয়ার আগে X exact centre-এ lock করা।
	player.global_position.x = tunnel_position.x
	player.play_cinematic_animation("fall")

	# Open seal-এর মুখ পর্যন্ত vertical movement।
	var enter_tunnel := create_tween()
	enter_tunnel.tween_property(
		player,
		"global_position:y",
		tunnel_position.y + 25.0,
		0.22
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await enter_tunnel.finished

	if not is_inside_tree() or completed:
		return

	# এখন Arin seal sprite-এর পিছনে চলে যাবে।
	player.z_index = 39

	# সম্পূর্ণ vertically tunnel-এর নিচে পড়বে।
	var player_fall := create_tween()

	player_fall.tween_property(
		player,
		"global_position:y",
		tunnel_position.y + 280.0,
		0.70
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	player_fall.parallel().tween_property(
		player,
		"scale",
		original_player_scale * 0.35,
		0.70
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	player_fall.parallel().tween_property(
		player,
		"modulate:a",
		0.0,
		0.55
	).set_delay(0.10)

	await player_fall.finished

	if not is_inside_tree() or completed:
		return

	# complete_level() victory animation চালালেও Arin invisible থাকবে।
	# তাই হাত তুলে দাঁড়ানোর pose দেখা যাবে না।
	player.visible = false

	sequence_state = SequenceState.COMPLETED
	complete_level()


func _forest_art() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(world_width, 0.0),
		Vector2(world_width, 900.0),
		Vector2(0.0, 900.0),
	])
	sky.color = Color("342c50")
	sky.z_index = -29
	add_child(sky)

	var field := Polygon2D.new()
	field.polygon = PackedVector2Array([
		Vector2(0.0, 720.0),
		Vector2(1900.0, 720.0),
		Vector2(1900.0, 900.0),
		Vector2(0.0, 900.0),
	])
	field.color = Color("456d4a")
	field.z_index = -19
	add_child(field)

	for i in 18:
		var tree := Polygon2D.new()
		var x := 1900.0 + float(i) * 95.0
		tree.polygon = PackedVector2Array([
			Vector2(x, 900.0),
			Vector2(x + 42.0, 420.0 - randi_range(0, 120)),
			Vector2(x + 84.0, 900.0),
		])
		tree.color = Color("132b2d")
		tree.z_index = -20
		add_child(tree)

	for i in 9:
		var cloud := Polygon2D.new()
		var x := 120.0 + float(i) * 320.0
		cloud.polygon = PackedVector2Array([
			Vector2(x, 180.0),
			Vector2(x + 90.0, 145.0),
			Vector2(x + 190.0, 185.0),
			Vector2(x + 110.0, 220.0),
		])
		cloud.color = Color(0.75, 0.58, 0.66, 0.18)
		cloud.z_index = -27
		add_child(cloud)

func _set_ball_arc_progress(
	progress: float,
	start_position: Vector2,
	control_position: Vector2,
	end_position: Vector2
) -> void:
	var first_line := start_position.lerp(
		control_position,
		progress
	)

	var second_line := control_position.lerp(
		end_position,
		progress
	)

	football.global_position = first_line.lerp(
		second_line,
		progress
	)
func _on_player_kicked_near_seal(
	charged: bool,
	kick_origin: Vector2,
	kick_direction: Vector2
) -> void:
	if transition_started:
		return

	if sequence_state != SequenceState.PLAYER_CONTROL:
		return

	if seal == null or not is_instance_valid(seal):
		return

	if not seal.can_receive_kick():
		return

	var distance_to_seal := kick_origin.distance_to(
		seal.global_position
	)

	# Arin seal-এর কাছে থেকে kick করলে নিশ্চিতভাবে detect হবে।
	if distance_to_seal > 220.0:
		return

	seal.attempt_kick(
		1.0,
		1,
		kick_direction,
		charged,
		player
	)
