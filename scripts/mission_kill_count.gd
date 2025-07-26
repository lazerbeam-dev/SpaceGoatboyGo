extends MissionGoal
class_name KillCountGoal

@export var target_tag: String = "mushroom"
@export var required_kills: int = 5
var current_kills: int = 0

func register_kill(victim_tag: String):
	if victim_tag == target_tag:
		current_kills += 1

func is_complete() -> bool:
	return current_kills >= required_kills
	
func get_target_kills() -> int:
	return required_kills

func get_progress() -> float:
	return clamp(float(current_kills) / float(required_kills), 0.0, 1.0)
