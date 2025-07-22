extends Resource
class_name MissionFailCondition

@export var description: String = "Generic mission fail condition."

func is_failed() -> bool:
	# Override in subclasses to define fail condition
	return false

func get_reason() -> String:
	# Reason to display or log if failed
	return description
