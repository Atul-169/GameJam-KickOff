class_name EchoSequenceTracker
extends RefCounted

enum Result { CORRECT, WRONG, COMPLETED, IGNORED }

var order: Array[String] = ["EAR", "EYE", "MOUTH"]
var progress := 0
var solved := false

func configure(value: Array[String]) -> void:
    order = value.duplicate()
    reset()

func register(rune_id: String) -> Result:
    if solved or order.is_empty():
        return Result.IGNORED
    if progress < order.size() and rune_id == order[progress]:
        progress += 1
        if progress >= order.size():
            solved = true
            return Result.COMPLETED
        return Result.CORRECT
    reset()
    return Result.WRONG

func reset() -> void:
    progress = 0
    solved = false
