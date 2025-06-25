extends Camera2D
class_name CameraFollower

@export var target_path: NodePath
@export var rotation_speed: float = 5.0  # Degrees per second
@export var follow_position := true

var target: Node2D

func _ready():
	target = get_node_or_null(target_path)
	if not target:
		push_error("Camera target not found.")

func _process(delta):
	if not is_instance_valid(target):
		return

	# Follow target position
	if follow_position:
		global_position = target.global_position

	# Get direction from planet to target
	var planet_center := Vector2.ZERO  # Change if needed
	var up_direction := (target.global_position - planet_center).normalized()
	var angle_to_up := up_direction.angle() + PI / 2  # Make 'up' match +Y

	# Smooth rotate
	rotation = lerp_angle(rotation, angle_to_up, rotation_speed * delta)
