extends Camera2D
class_name CameraFollower

@export var target_path: NodePath
@export var rotation_speed: float = 5.0  # Degrees per second
@export var follow_position := true

var target: Node2D

# Shake-related
var shake_intensity := 0.0
var shake_duration := 0.0
var shake_timer := 0.0
var shake_offset := Vector2.ZERO

func start_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
func _process(delta):
	if not is_instance_valid(target):
		return

	# Follow position
	if follow_position:
		global_position = target.global_position + shake_offset

	# Smooth rotate to match planet orientation
	var planet_center := Vector2.ZERO  # Modify if your planet has actual center
	var up_direction := (target.global_position - planet_center).normalized()
	var angle_to_up := up_direction.angle() + PI / 2
	rotation = lerp_angle(rotation, angle_to_up, rotation_speed * delta)

	# Apply screen shake
	if shake_timer > 0.0:
		shake_timer -= delta
		var falloff := shake_timer / shake_duration
		shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_intensity * falloff
	else:
		shake_offset = Vector2.ZERO
