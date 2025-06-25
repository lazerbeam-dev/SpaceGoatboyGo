extends CharacterBody2D
class_name DroppedItemBody

var gravity_dir := Vector2.DOWN
@export var gravity_strength := 1
var up_dir := Vector2.UP
var is_grounded := false

func _ready():
	print("DroppedItemBody ready. gravity_dir =", gravity_dir)
	up_dir = -gravity_dir.normalized()
	up_direction = up_dir
	set_floor_stop_on_slope_enabled(true)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	# Apply gravity in correct direction
	gravity_dir = gravity_dir.normalized()
	up_dir = -gravity_dir
	up_direction = up_dir

	velocity += gravity_dir * gravity_strength * delta

	# Project current velocity along tangent + up
	var right_dir = Vector2(-up_dir.y, up_dir.x)
	var tangent_speed = velocity.dot(right_dir)
	var normal_speed = velocity.dot(up_dir)

	# Simple ground stick / friction simulation
	is_grounded = is_on_floor() and velocity.dot(up_dir) <= 0
	if is_grounded:
		tangent_speed = move_toward(tangent_speed, 0.0, 1600.0 * delta)

	# Compose final velocity
	velocity = right_dir * tangent_speed + up_dir * normal_speed

	# Clamp extremes
	velocity.x = clamp(velocity.x, -800.0, 800.0)
	velocity.y = clamp(velocity.y, -1200.0, 1200.0)

	move_and_slide()
