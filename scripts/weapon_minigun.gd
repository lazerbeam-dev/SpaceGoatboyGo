extends Weapon
class_name MinigunWeapon

@export var fire_rate := 0.05           # Time between shots (not shots/sec)
@export var barrel_radius := 0.5        # Radius of the rotation circle
var _fire_timer := 0.0
var _barrel_index := 0                  # 0–5 for 6 positions around circle

func attempt_fire(direction: Vector2, global_time: float) -> void:
	if global_time - _last_fired_time < fire_rate:
		return

	_last_fired_time = global_time
	fire(direction)
	advance_barrel_position()

func fire(direction: Vector2):
	spawn_projectile(direction)
	emit_signal("fire_signal")  # Triggers muzzle flash etc.

func advance_barrel_position():
	var angle_step := TAU / 6.0  # 60 degrees
	var angle := _barrel_index * angle_step
	barrel.position += Vector2(cos(angle), sin(angle)) * barrel_radius
	_barrel_index = (_barrel_index + 1) % 6
