extends Weapon
class_name ShotgunWeapon

@export var num_pellets := 6
@export var spread_angle_degrees := 15.0

func attempt_fire(direction: Vector2, global_time: float) -> void:
	emit_signal("fire_signal") 
	if global_time - _last_fired_time < cooldown:
		return

	if direction.length() < 0.1:
		push_warning("ShotgunWeapon: direction vector too small: %s" % direction)
		return

	_last_fired_time = global_time
	var half_spread_rad = deg_to_rad(spread_angle_degrees) / 2.0

	for i in range(num_pellets):
		var angle_offset_rad = lerp(-half_spread_rad, half_spread_rad, float(i) / (num_pellets - 1.0)) if num_pellets > 1 else 0.0
		var pellet_direction = direction.rotated(angle_offset_rad)
		print("Pellet %d: %.2f° | Dir: %s" % [i, rad_to_deg(angle_offset_rad), pellet_direction])
		spawn_projectile(pellet_direction)
