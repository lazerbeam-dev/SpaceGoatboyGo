extends Resource
class_name MissionBounds

@export var description: String = "Generic mission boundary."

func is_inside(_position: Vector2) -> bool:
	print("is this what we are")
	return true
