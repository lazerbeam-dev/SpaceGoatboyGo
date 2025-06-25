extends CharacterBody2D
class_name FlyingPatroller

@export var planet_path: NodePath
@export var gravity_strength := 0.0  # Still needed for correct up_direction
@export var orbit_speed := 100.0     # Base horizontal patrol speed
@export var sine_amplitude := 30.0   # Height of the sine wave
@export var sine_frequency := 2.0    # Speed of sine wave undulation
@export var patrol_period := 3.0     # Time to switch direction (seconds)

var planet: Node2D
var gravity_dir := Vector2.DOWN
var direction := 1                   # 1 = clockwise, -1 = counterclockwise
var time := 0.0
var facing_right := true

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
		push_error("FlyingPatroller: No planet found.")

func _physics_process(delta):
	if not planet:
		return
	
	time += delta
	
	# Orbiting around the planet
	var to_center = (planet.global_position - global_position).normalized()
	gravity_dir = to_center
	up_direction = -to_center
	
	# Tangent = 90° to gravity
	var tangent = Vector2(-to_center.y, to_center.x) * direction
	
	# Add sine wave on radial axis (like flapping up and down)
	var sine_offset = sin(time * TAU * sine_frequency) * sine_amplitude
	var radial_velocity = to_center * sine_offset
	
	# Total velocity: orbit tangent + sine bobbing
	velocity = tangent * orbit_speed + radial_velocity
	
	# Face in orbital direction using up_direction like land creatures
	rotation = up_direction.angle() + PI / 2
	
	# Determine which way we should be facing based on tangent direction
	var should_face_right = tangent.x > 0
	
	# Only flip if we need to change facing direction
	if should_face_right != facing_right:
		facing_right = should_face_right
		if has_node("Model"):
			var model = get_node("Model")
			model.scale.x = abs(model.scale.x) * (1 if facing_right else -1)
	
	move_and_slide()
	
	# Periodic direction flip
	if patrol_period > 0.0 and int(time / patrol_period) % 2 == 1:
		direction = -1
	else:
		direction = 1
