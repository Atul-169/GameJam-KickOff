extends Node

signal kickoff_started(room_id: String)
signal time_added(seconds: float)
signal objective_changed(text: String)
signal puzzle_solved(puzzle_id: String)
signal player_damaged(amount: int)
signal player_health_changed(current: int, maximum: int)
signal player_died
signal checkpoint_reached(checkpoint_id: String)
signal level_completed(level_id: String)
signal boss_defeated
signal friend_rescued
signal restart_requested
signal main_menu_requested
signal player_kicked(charged: bool, origin: Vector2, direction: Vector2)
signal dialogue_requested(speaker: String, text: String, duration: float)
signal dialogue_active_changed(active: bool)
signal dialogue_clear_requested
signal challenge_failed(reason: String)
signal boss_phase_changed(phase: int)
signal truth_pulse_requested
signal settings_changed
signal kick_charge_changed(value: float)
signal cutscene_started
signal cutscene_ended
