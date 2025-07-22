extends Resource
class_name MissionGoal

@export var description: String = "Generic mission goal."

func is_complete() -> bool:
	# Override in subclasses to define goal completion
	return false

func get_progress() -> float:
	# 0.0 to 1.0 progress value (optional, used by UI or feedback systems)
	return 0.0
