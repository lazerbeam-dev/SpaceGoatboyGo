extends Node2D
class_name Arm

@export var default_direction := Vector2.RIGHT
@export var is_mirrored := false  # If body is flipped (facing left)

# The arm rotates to this direction each frame, relative to the body
var target_direction := Vector2.RIGHT

func _process(_delta):
	update_rotation()

func update_rotation():
	if target_direction == Vector2.ZERO:
		return

	var aim = target_direction.normalized()

	if is_mirrored:
		aim.x *= -1  # Flip horizontally

	rotation = aim.angle()
