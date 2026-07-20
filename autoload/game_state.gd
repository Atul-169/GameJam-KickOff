extends Node

enum GameMode { INTRO, FROZEN, ACTIVE, COMPLETED, FAILED, PAUSED }

var game_state: GameMode = GameMode.INTRO
var current_level_id: String = ""
var max_health: int = 5
var current_health: int = 5
var max_stars: int = 5
var current_stars: int = 5
var sigils: Dictionary = {
    "time": false,
    "echo": false,
    "force": false,
    "truth": false,
}
var completed_levels: Dictionary = {}
var damage_taken: int = 0
var mistakes: int = 0
var level_start_time_msec: int = 0
var escape_checkpoint: bool = false

var dialogue_active: bool = false
var dialogue_input_release_guard: bool = false
var _dialogue_release_armed_frame: int = -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
    if not dialogue_input_release_guard:
        return
    if Engine.get_process_frames() <= _dialogue_release_armed_frame:
        return
    if _dialogue_advance_inputs_held():
        return
    dialogue_input_release_guard = false

func set_dialogue_active(active: bool) -> void:
    if active:
        dialogue_input_release_guard = false
        _dialogue_release_armed_frame = -1
    if dialogue_active == active:
        return
    dialogue_active = active
    if not active:
        _arm_dialogue_release_guard()
    EventBus.dialogue_active_changed.emit(active)

func clear_dialogue_state(suppress_closing_input: bool = true) -> void:
    var changed := dialogue_active
    dialogue_active = false
    if suppress_closing_input:
        _arm_dialogue_release_guard()
    else:
        dialogue_input_release_guard = false
        _dialogue_release_armed_frame = -1
    if changed:
        EventBus.dialogue_active_changed.emit(false)

func is_gameplay_input_blocked() -> bool:
    return dialogue_active or dialogue_input_release_guard

func _arm_dialogue_release_guard() -> void:
    dialogue_input_release_guard = true
    _dialogue_release_armed_frame = Engine.get_process_frames()

func _dialogue_advance_inputs_held() -> bool:
    return (
        Input.is_key_pressed(KEY_E)
        or Input.is_key_pressed(KEY_ENTER)
        or Input.is_key_pressed(KEY_KP_ENTER)
        or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    )

func reset_run() -> void:
    clear_dialogue_state(false)
    game_state = GameMode.INTRO
    current_level_id = ""
    current_health = max_health
    current_stars = max_stars
    damage_taken = 0
    mistakes = 0
    escape_checkpoint = false
    completed_levels.clear()
    for key: String in sigils.keys():
        sigils[key] = false

func begin_level(id: String) -> void:
    clear_dialogue_state(false)
    current_level_id = id
    current_health = max_health
    current_stars = max_stars
    damage_taken = 0
    mistakes = 0
    level_start_time_msec = Time.get_ticks_msec()
    game_state = GameMode.FROZEN

func consume_star() -> bool:
    if current_stars <= 0:
        return false
    current_stars -= 1
    EventBus.star_ammo_changed.emit(current_stars, max_stars)
    return true

func refill_stars() -> void:
    current_stars = max_stars
    EventBus.star_ammo_changed.emit(current_stars, max_stars)

func add_sigil(id: String) -> bool:
    if not sigils.has(id) or bool(sigils[id]):
        return false
    sigils[id] = true
    return true

func has_sigil(id: String) -> bool:
    return bool(sigils.get(id, false))

func has_all_sigils() -> bool:
    return sigil_count() == sigils.size()

func mark_level_completed(id: String) -> bool:
    if id.is_empty() or completed_levels.has(id):
        return false
    completed_levels[id] = true
    return true

func sigil_count() -> int:
    var count := 0
    for value: bool in sigils.values():
        if value:
            count += 1
    return count

func elapsed_seconds() -> float:
    return float(Time.get_ticks_msec() - level_start_time_msec) / 1000.0

func calculate_rank(time_remaining: float, uses_timer: bool) -> String:
    var score := 100 - damage_taken * 12 - mistakes * 8
    if uses_timer:
        score += int(maxf(time_remaining, 0.0))
    if score >= 100:
        return "S"
    if score >= 80:
        return "A"
    if score >= 60:
        return "B"
    return "C"
