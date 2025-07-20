extends SGEntity
class_name FlyingSeeker

@export var planet_path: NodePath
@export var acceleration: float = 600.0  # How quickly it changes velocity
@export var max_speed: float = 300.0     # Max movement speed
@export var drag: float = 0.1            # Slows down if no input

var gravity_dir := Vector2.DOWN
var facing_right := true # This should be set externally

@onready var model := get_node_or_null("Model")

func _ready():
	planet = get_node_or_null(planet_path)
	if not planet:
		var current = self
		while current:
			if current.name == "Game":
				planet = current.get_node_or_null("Planet")
				break
			current = current.get_parent()
	if not planet:
		push_error("FlyingSeeker: No planet found.")
	motile = true

func _physics_process(delta):
	if not planet:
		return

	var to_center = (planet.global_position - global_position).normalized()
	gravity_dir = to_center
	up_direction = -to_center

	# Accelerate toward input
	if move_input.length() > 0.01:
		var desired_velocity = move_input.normalized() * max_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

	move_and_slide()

	# Face in movement direction
	if velocity.length() > 1.0:
		rotation = up_direction.angle() + PI / 2
		var should_face_right = velocity.x > 0
		if should_face_right != facing_right:
			facing_right = should_face_right
			if model:
				model.scale.x = abs(model.scale.x) * (1 if facing_right else -1)
