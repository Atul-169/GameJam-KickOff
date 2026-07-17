extends Node
const LEVEL_IDS: Array[String] = ["prologue", "level_01", "level_02", "level_03", "level_04"]
const LEVELS: Array[String] = [
    "res://scenes/levels/prologue_forest.tscn",
    "res://scenes/levels/level_01_gear_hall.tscn",
    "res://scenes/levels/level_02_echo_archive.tscn",
    "res://scenes/levels/level_03_guardian_court.tscn",
    "res://scenes/levels/level_04_sealed_heart.tscn"
]
func path_for_index(index: int) -> String:
    return LEVELS[index] if index >= 0 and index < LEVELS.size() else ""
func index_for_level(id: String) -> int: return LEVEL_IDS.find(id)
func next_path(id: String) -> String: return path_for_index(index_for_level(id) + 1)
