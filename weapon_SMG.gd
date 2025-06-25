extends Weapon
class_name SMGWeapon

@export var burst_count := 3
@export var burst_delay := 0.05  # seconds between burst shots

var _burst_shots_remaining := 0
var _burst_direction := Vector2.ZERO
var _burst_timer := 0.0

func attempt_fire(direction: Vector2, global_time: float) -> void:
	if global_time - _last_fired_time < cooldown:
		return
	_last_fired_time = global_time
	_burst_shots_remaining = burst_count
	_burst_direction = direction
	_burst_timer = 0.0
	fire(_burst_direction)  # first shot immediately

func _process(delta):
	if _burst_shots_remaining > 1:
		_burst_timer += delta
		if _burst_timer >= burst_delay:
			_burst_timer = 0.0
			_burst_shots_remaining -= 1
			fire(_burst_direction)
