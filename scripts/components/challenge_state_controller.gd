class_name ChallengeStateController
extends Node
signal state_changed(previous: GameState.GameMode, current: GameState.GameMode)
var state: GameState.GameMode = GameState.GameMode.INTRO
func set_state(next: GameState.GameMode) -> void:
 if next==state:return
 var previous:=state;state=next;GameState.game_state=next;state_changed.emit(previous,next)
 get_tree().call_group("freezable","set_world_active",next==GameState.GameMode.ACTIVE)
func freeze() -> void:set_state(GameState.GameMode.FROZEN)
func activate() -> void:set_state(GameState.GameMode.ACTIVE)
func complete() -> void:set_state(GameState.GameMode.COMPLETED)
func fail() -> void:set_state(GameState.GameMode.FAILED)
