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

var niko: NikoCharacter
var football: Football
var seal: AncientSeal
var astra_visual: Node2D
var astra_float_tween: Tween

var sequence_state := SequenceState.INTRO_START
var transition_started := false
var cinematic_generation := 0


func _init() -> void:
	level_id = "prologue"
	level_title = "Prologue: The Lost Ball"
	music_key = "forest_music"
	world_width = 3500.0
	checkpoint_position = Vector2(340.0, GROUND_Y)


func build_level() -> void:
	transition_started = false
	sequence_state = SequenceState.INTRO_START

	_forest_art()

	football = spawn_scene(
		"res://scenes/interactables/football.tscn",
		Vector2(520.0, FOOTBALL_GROUND_Y)
	) as Football

	niko = spawn_scene(
		"res://scenes/characters/niko.tscn",
		Vector2(850.0, GROUND_Y)
	) as NikoCharacter

	seal = AncientSeal.new()
	seal.position = Vector2(SEAL_X, GROUND_Y - 96.0)
	seal.enabled = true
	seal.interaction_enabled = false
	seal.kick_enabled = false
	add_child(seal)
	seal.kicked_open.connect(_seal_kicked)


func post_ready() -> void:
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

	var ball_arc := create_tween()
	ball_arc.tween_property(
		football,
		"global_position",
		Vector2(1050.0, 720.0),
		0.55
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ball_arc.tween_property(
		football,
		"global_position",
		Vector2(1700.0, 790.0),
		0.60
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ball_arc.tween_property(
		football,
		"global_position",
		Vector2(BALL_FOREST_X, FOOTBALL_GROUND_Y),
		0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var ball_spin := create_tween()
	ball_spin.tween_property(football, "rotation", TAU * 5.0, 1.80)

	await ball_arc.finished
	if not _cinematic_valid(token):
		return

	# The ball is explicitly grounded when the arc finishes.
	football.global_position.y = FOOTBALL_GROUND_Y
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
		FOOTBALL_GROUND_Y
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
	# SHOT 5: Niko falls at a point slightly right of the seal
	# --------------------------------------------------------------
	sequence_state = SequenceState.NIKO_FALLING
	niko.play_state("fall")

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

	var niko_fall := create_tween()
	niko_fall.tween_property(
		niko,
		"global_position",
		Vector2(
			SEAL_X + NIKO_FALL_X_OFFSET,
			GROUND_Y + 430.0
		),
		1.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	
	await niko_fall.finished
	if not _cinematic_valid(token):
		return

	niko.visible = false
	football.global_position.y = FOOTBALL_GROUND_Y

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
		Vector2(70.0, 90.0),
		Color("4de3ff"),
        "ASTRA"
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
		FOOTBALL_GROUND_Y
	)

	# The cinematic already performed the failed hand attempt.
	seal.hand_used = true
	seal.set_interaction_enabled(false)
	seal.set_kick_enabled(true)

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

	seal.disable_detection_keep_visible()
	set_restart_blocked(true)

	if hud.has_method("set_state_panel_visible"):
		hud.call("set_state_panel_visible", true)

	hud.set_world_state(false)
	set_objective("")

	var entrance := Polygon2D.new()
	entrance.name = "UndergroundEntrance"
	entrance.polygon = PackedVector2Array([
		Vector2(-110.0, -20.0),
		Vector2(110.0, -20.0),
		Vector2(155.0, 110.0),
		Vector2(-155.0, 110.0),
	])
	entrance.color = Color("071018")
	entrance.global_position = seal.global_position
	entrance.z_index = -1
	add_child(entrance)

	AudioManager.play_sfx("kickoff_sfx")
	hud.show_message("KICKOFF!", 1.2)

	var seal_fade := create_tween()
	seal_fade.tween_property(seal, "modulate:a", 0.0, 0.55)
	await seal_fade.finished

	if not is_inside_tree() or completed:
		return

	var dialogue_ok := await hud.show_dialogue_sequence(
		[
			{
				"speaker": "ARIN",
				"text": "Niko, hold on. I'm coming.",
				"duration": 2.0,
			},
		],
		true
	)

	if dialogue_ok and is_inside_tree() and not completed:
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
