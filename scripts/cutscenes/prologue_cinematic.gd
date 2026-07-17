class_name PrologueCinematic
extends Node

enum State {
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

var state: State = State.INTRO_START
var level: PrologueForest
var arin: ArinController
var niko: NikoCharacter
var football: Football
var seal: AncientSeal
var hud: GameHUD
var cinematic_camera: Camera2D
var astra_visual: Node2D
var opening_visual: Polygon2D
var astra_particles: CPUParticles2D
var running := false
var duration_scale := 1.0
var _generation := 0
var _active_tweens: Array[Tween] = []

func configure(
    owner_level: PrologueForest,
    player: ArinController,
    friend: NikoCharacter,
    ball: Football,
    ancient_seal: AncientSeal,
    game_hud: GameHUD
) -> void:
    level = owner_level
    arin = player
    niko = friend
    football = ball
    seal = ancient_seal
    hud = game_hud

func start_cinematic() -> void:
    if running or not _references_valid():
        return
    running = true
    _generation += 1
    call_deferred("_run_cinematic", _generation)

func cancel() -> void:
    _generation += 1
    running = false
    for tween in _active_tweens:
        if tween != null and tween.is_valid():
            tween.kill()
    _active_tweens.clear()
    if hud != null and is_instance_valid(hud):
        hud.clear_dialogue_queue()
    if arin != null and is_instance_valid(arin):
        arin.set_cinematic_control(false)
    if cinematic_camera != null and is_instance_valid(cinematic_camera):
        cinematic_camera.enabled = false
    GameState.clear_dialogue_state(false)

func _exit_tree() -> void:
    cancel()

func _run_cinematic(token: int) -> void:
    _prepare_intro()
    var ok := await _shot_establishing_field(token)
    if ok:
        ok = await _shot_arin_kicks(token)
    if ok:
        ok = await _shot_running_to_forest(token)
    if ok:
        ok = await _shot_ball_on_seal(token)
    if ok:
        ok = await _shot_niko_falls(token)
    if ok:
        ok = await _shot_arin_push_fail(token)
    if ok:
        ok = await _shot_astra_appears(token)
    if ok:
        await _begin_player_control(token)

func _prepare_intro() -> void:
    state = State.INTRO_START
    level.sequence_state = PrologueForest.SequenceState.INTRO_START
    level.set_restart_blocked(true)
    level.state_controller.set_state(GameState.GameMode.INTRO)
    level.canvas_modulate.color = Color.WHITE
    hud.set_gameplay_hud_visible(false)
    hud.set_objective("")
    EventBus.cutscene_started.emit()

    arin.global_position = Vector2(340, 810)
    arin.set_cinematic_control(true)
    arin.set_cinematic_facing(1)
    arin.play_cinematic_animation("idle")

    niko.global_position = Vector2(850, 810)
    niko.visible = true
    niko.set_cinematic_control(true)
    niko.set_cinematic_facing(-1)
    niko.play_state("idle")

    football.set_cinematic_control(true)
    football.global_position = Vector2(520, 810)
    football.rotation = 0.0

    seal.set_enabled(true)
    seal.set_interaction_enabled(false)
    seal.set_kick_enabled(false)
    seal.set_hand_attempted(false)
    seal.modulate = Color.WHITE

    cinematic_camera = Camera2D.new()
    cinematic_camera.name = "PrologueCinematicCamera"
    cinematic_camera.position = Vector2(560, 620)
    cinematic_camera.limit_left = 0
    cinematic_camera.limit_top = 0
    cinematic_camera.limit_right = int(level.world_width)
    cinematic_camera.limit_bottom = int(level.world_height)
    cinematic_camera.position_smoothing_enabled = false
    level.add_child(cinematic_camera)
    arin.camera.enabled = false
    cinematic_camera.enabled = true
    cinematic_camera.make_current()

func _shot_establishing_field(token: int) -> bool:
    state = State.FIELD_ESTABLISHING
    level.sequence_state = PrologueForest.SequenceState.FIELD_ESTABLISHING
    _tween_property(
        cinematic_camera,
        "position",
        Vector2(690, 620),
        1.5,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )
    if not await _wait(0.35, token):
        return false
    return await _show_lines(
        [
            {
                "speaker": "NIKO",
                "text": "Pass it here, Arin!",
                "duration": 1.9,
            },
        ],
        token
    )

func _shot_arin_kicks(token: int) -> bool:
    state = State.ARIN_KICKING
    level.sequence_state = PrologueForest.SequenceState.ARIN_KICKING
    arin.set_cinematic_facing(1)
    arin.play_cinematic_animation("kick")
    if not await _wait(0.25, token):
        return false

    state = State.BALL_TO_FOREST
    level.sequence_state = PrologueForest.SequenceState.BALL_TO_FOREST
    var ball_tween := _new_tween()
    ball_tween.set_trans(Tween.TRANS_QUAD)
    ball_tween.set_ease(Tween.EASE_OUT)
    ball_tween.tween_property(
        football, "global_position", Vector2(1060, 690), _scaled(0.55)
    )
    ball_tween.tween_property(
        football, "global_position", Vector2(1540, 640), _scaled(0.50)
    )
    ball_tween.set_ease(Tween.EASE_IN)
    ball_tween.tween_property(
        football, "global_position", Vector2(1940, 785), _scaled(0.65)
    )
    _tween_property(
        football,
        "rotation",
        TAU * 5.0,
        1.70,
        Tween.TRANS_LINEAR,
        Tween.EASE_IN_OUT
    )
    _tween_property(
        cinematic_camera,
        "position",
        Vector2(1420, 610),
        1.70,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )
    return await _show_lines(
        [
            {
                "speaker": "NIKO",
                "text": "Too much power, Arin!",
                "duration": 1.9,
            },
            {
                "speaker": "ARIN",
                "text": "I meant to do that.",
                "duration": 1.7,
            },
            {
                "speaker": "NIKO",
                "text": "Of course you did. Come on, let's get it.",
                "duration": 2.5,
            },
        ],
        token
    )

func _shot_running_to_forest(token: int) -> bool:
    state = State.FRIENDS_RUNNING
    level.sequence_state = PrologueForest.SequenceState.FRIENDS_RUNNING
    niko.set_cinematic_facing(1)
    arin.set_cinematic_facing(1)
    niko.play_state("run")
    arin.play_cinematic_animation("run")

    var movement := _new_tween()
    movement.set_parallel(true)
    movement.set_trans(Tween.TRANS_SINE)
    movement.set_ease(Tween.EASE_IN_OUT)
    movement.tween_property(
        niko, "global_position", Vector2(2700, 810), _scaled(3.2)
    )
    movement.tween_property(
        arin, "global_position", Vector2(2440, 810), _scaled(3.35)
    ).set_delay(_scaled(0.18))
    movement.tween_property(
        cinematic_camera, "position", Vector2(2440, 620), _scaled(3.2)
    )

    var ball_path := _new_tween()
    ball_path.set_trans(Tween.TRANS_SINE)
    ball_path.set_ease(Tween.EASE_IN_OUT)
    ball_path.tween_property(
        football, "global_position", Vector2(2480, 705), _scaled(1.4)
    )
    ball_path.tween_property(
        football, "global_position", Vector2(3000, 790), _scaled(1.65)
    )
    _tween_property(
        football,
        "rotation",
        football.rotation + TAU * 4.0,
        3.05,
        Tween.TRANS_LINEAR,
        Tween.EASE_IN_OUT
    )
    if not await _wait(3.45, token):
        return false
    niko.global_position = Vector2(2700, 810)
    arin.global_position = Vector2(2440, 810)
    football.global_position = Vector2(3000, 790)
    niko.play_state("idle")
    arin.play_cinematic_animation("idle")
    return true

func _shot_ball_on_seal(token: int) -> bool:
    state = State.BALL_ON_SEAL
    level.sequence_state = PrologueForest.SequenceState.BALL_ON_SEAL
    _tween_property(
        cinematic_camera,
        "position",
        Vector2(2940, 620),
        0.9,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )
    niko.play_state("run")
    var approach := _tween_property(
        niko,
        "global_position",
        Vector2(2910, 810),
        0.95,
        Tween.TRANS_SINE,
        Tween.EASE_OUT
    )
    await approach.finished
    if not _valid(token):
        return false
    state = State.NIKO_APPROACHING
    level.sequence_state = PrologueForest.SequenceState.NIKO_APPROACHING
    niko.play_state("idle")
    return await _show_lines(
        [
            {
                "speaker": "NIKO",
                "text": "Found it.",
                "duration": 1.5,
            },
        ],
        token
    )

func _shot_niko_falls(token: int) -> bool:
    state = State.NIKO_FALLING
    level.sequence_state = PrologueForest.SequenceState.NIKO_FALLING
    opening_visual = Polygon2D.new()
    opening_visual.name = "CinematicSealOpening"
    opening_visual.polygon = PackedVector2Array([
        Vector2(-105, -24),
        Vector2(105, -24),
        Vector2(145, 105),
        Vector2(-145, 105),
    ])
    opening_visual.color = Color("041018")
    opening_visual.global_position = seal.global_position
    opening_visual.modulate.a = 0.0
    opening_visual.z_index = -1
    level.add_child(opening_visual)

    var glow := _new_tween()
    glow.set_trans(Tween.TRANS_SINE)
    glow.set_ease(Tween.EASE_IN_OUT)
    glow.tween_property(seal, "modulate", Color("63efff"), _scaled(0.35))
    glow.tween_property(seal, "scale", Vector2(1.08, 1.08), _scaled(0.20))
    glow.tween_property(seal, "scale", Vector2.ONE, _scaled(0.20))
    if not await _wait(0.72, token):
        return false

    seal.modulate.a = 0.0
    opening_visual.modulate.a = 1.0
    niko.play_state("fall")
    var fall := _new_tween()
    fall.set_parallel(true)
    fall.set_trans(Tween.TRANS_QUAD)
    fall.set_ease(Tween.EASE_IN)
    fall.tween_property(
        niko, "global_position", niko.global_position + Vector2(0, 455), _scaled(1.05)
    )
    fall.tween_property(
        football, "global_position", Vector2(2845, 810), _scaled(0.75)
    )
    fall.tween_property(
        football, "rotation", football.rotation - TAU * 1.2, _scaled(0.75)
    )

    arin.play_cinematic_animation("run")
    var arin_run := _new_tween()
    arin_run.set_trans(Tween.TRANS_SINE)
    arin_run.set_ease(Tween.EASE_OUT)
    arin_run.tween_property(
        arin,
        "global_position",
        Vector2(2780, 810),
        _scaled(1.20)
    ).set_delay(_scaled(0.28))
    _tween_property(
        cinematic_camera,
        "position",
        Vector2(2960, 625),
        1.15,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )

    if not await _show_lines(
        [
            {
                "speaker": "ARIN",
                "text": "Niko!",
                "duration": 1.6,
            },
        ],
        token
    ):
        return false
    if not await _wait(0.15, token):
        return false
    niko.visible = false
    state = State.SEAL_CLOSING
    level.sequence_state = PrologueForest.SequenceState.SEAL_CLOSING
    seal.modulate = Color.WHITE
    opening_visual.modulate.a = 0.0
    arin.play_cinematic_animation("idle")
    return await _wait(0.55, token)

func _shot_arin_push_fail(token: int) -> bool:
    state = State.ARIN_PUSH_FAIL
    level.sequence_state = PrologueForest.SequenceState.ARIN_PUSH_FAIL
    arin.set_cinematic_facing(1)
    arin.play_cinematic_animation("run")
    var move := _tween_property(
        arin,
        "global_position",
        Vector2(2880, 810),
        0.70,
        Tween.TRANS_SINE,
        Tween.EASE_OUT
    )
    await move.finished
    if not _valid(token):
        return false
    arin.play_cinematic_animation("push_fail")
    seal.set_hand_attempted(true)
    if not await _wait(0.80, token):
        return false
    arin.play_cinematic_animation("idle")
    return await _show_lines(
        [
            {
                "speaker": "ARIN",
                "text": "It won't move!",
                "duration": 1.9,
            },
        ],
        token
    )

func _shot_astra_appears(token: int) -> bool:
    state = State.ASTRA_APPEARING
    level.sequence_state = PrologueForest.SequenceState.ASTRA_APPEARING
    astra_visual = AssetRegistry.make_visual(
        "astra", Vector2(78, 98), Color("4de3ff"), "ASTRA"
    )
    astra_visual.name = "AstraMap"
    astra_visual.global_position = seal.global_position + Vector2(120, -120)
    astra_visual.scale = Vector2(0.25, 0.25)
    astra_visual.modulate.a = 0.0
    level.add_child(astra_visual)
    level.astra_visual = astra_visual

    astra_particles = CPUParticles2D.new()
    astra_particles.name = "AstraParticles"
    astra_particles.amount = 18
    astra_particles.lifetime = 1.2
    astra_particles.one_shot = true
    astra_particles.explosiveness = 0.75
    astra_particles.direction = Vector2.UP
    astra_particles.spread = 65.0
    astra_particles.initial_velocity_min = 35.0
    astra_particles.initial_velocity_max = 95.0
    astra_particles.gravity = Vector2(0, -15)
    astra_particles.scale_amount_min = 2.0
    astra_particles.scale_amount_max = 5.0
    astra_particles.color = Color("5deeff")
    astra_particles.global_position = astra_visual.global_position
    level.add_child(astra_particles)
    astra_particles.emitting = true

    _tween_property(
        cinematic_camera,
        "position",
        Vector2(3010, 610),
        0.75,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )
    var appear := _new_tween()
    appear.set_parallel(true)
    appear.set_trans(Tween.TRANS_BACK)
    appear.set_ease(Tween.EASE_OUT)
    appear.tween_property(
        astra_visual, "global_position", seal.global_position + Vector2(120, -185), _scaled(0.8)
    )
    appear.tween_property(
        astra_visual, "scale", Vector2.ONE, _scaled(0.8)
    )
    appear.tween_property(
        astra_visual, "modulate:a", 1.0, _scaled(0.55)
    )
    if not await _wait(0.95, token):
        return false

    state = State.ASTRA_DIALOGUE
    level.sequence_state = PrologueForest.SequenceState.ASTRA_DIALOGUE
    var dialogue_ok := await _show_lines(
        [
            {
                "speaker": "ASTRA MAP",
                "text": "HANDS COMMAND NOTHING HERE.",
                "duration": 2.3,
            },
            {
                "speaker": "ASTRA MAP",
                "text": "ONLY MOTION AWAKENS THE PATH.",
                "duration": 2.6,
            },
            {
                "speaker": "ARIN",
                "text": "What are you?",
                "duration": 1.9,
            },
            {
                "speaker": "ASTRA MAP",
                "text": "THE PATH BELOW HAS ONE RULE.",
                "duration": 2.6,
            },
            {
                "speaker": "ASTRA MAP",
                "text": "BEGIN WITH A KICK.",
                "duration": 2.1,
            },
        ],
        token
    )
    if not dialogue_ok:
        return false

    var float_tween := _new_tween()
    float_tween.set_loops()
    float_tween.set_trans(Tween.TRANS_SINE)
    float_tween.set_ease(Tween.EASE_IN_OUT)
    float_tween.tween_property(
        astra_visual,
        "global_position:y",
        astra_visual.global_position.y - 16.0,
        _scaled(0.75)
    )
    float_tween.tween_property(
        astra_visual,
        "global_position:y",
        astra_visual.global_position.y,
        _scaled(0.75)
    )
    return true

func _begin_player_control(token: int) -> bool:
    if not _valid(token):
        return false
    var camera_target := arin.global_position + Vector2(0, -160)
    var camera_return := _tween_property(
        cinematic_camera,
        "position",
        camera_target,
        0.75,
        Tween.TRANS_SINE,
        Tween.EASE_IN_OUT
    )
    await camera_return.finished
    if not _valid(token):
        return false

    state = State.PLAYER_CONTROL
    level.sequence_state = PrologueForest.SequenceState.PLAYER_CONTROL
    cinematic_camera.enabled = false
    arin.camera.enabled = true
    arin.camera.make_current()
    seal.set_hand_attempted(true)
    seal.set_interaction_enabled(false)
    seal.set_kick_enabled(true)
    hud.set_gameplay_hud_visible(true, false)
    level.set_objective("Kick the Ancient Seal")
    level.set_restart_blocked(false)
    arin.set_cinematic_control(false)
    EventBus.cutscene_ended.emit()
    running = false
    return true

func _show_lines(lines: Array, token: int) -> bool:
    if not _valid(token):
        return false
    var completed := await hud.show_dialogue_sequence(lines, false)
    return completed and _valid(token)

func _wait(seconds: float, token: int) -> bool:
    await get_tree().create_timer(_scaled(seconds)).timeout
    return _valid(token)

func _new_tween() -> Tween:
    var tween := create_tween()
    _active_tweens.append(tween)
    return tween

func _tween_property(
    target: Object,
    property: NodePath,
    final_value: Variant,
    seconds: float,
    transition: Tween.TransitionType,
    easing: Tween.EaseType
) -> Tween:
    var tween := _new_tween()
    tween.set_trans(transition)
    tween.set_ease(easing)
    tween.tween_property(target, property, final_value, _scaled(seconds))
    return tween

func _scaled(seconds: float) -> float:
    return maxf(seconds * duration_scale, 0.001)

func _valid(token: int) -> bool:
    return token == _generation and running and is_inside_tree() and _references_valid()

func _references_valid() -> bool:
    return (
        level != null
        and is_instance_valid(level)
        and arin != null
        and is_instance_valid(arin)
        and niko != null
        and is_instance_valid(niko)
        and football != null
        and is_instance_valid(football)
        and seal != null
        and is_instance_valid(seal)
        and hud != null
        and is_instance_valid(hud)
    )
