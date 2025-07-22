extends MissionBounds
class_name CircularMissionBounds

@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 1000.0

func is_inside(position: Vector2) -> bool:
	return center.distance_to(position) <= radius
