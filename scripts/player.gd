extends CharacterBody2D

const SPEED = 260.0
const JUMP_VELOCITY = -300.0
@export var planet_path: NodePath = "../Planet"
@export var pathwright_path: NodePath = "../Pathwright"
var gravity_strength := 980.0
var facing_right := true
var planet: Node2D
var arms_container : Node2D
var pathwright: Node = null
func _ready() -> void:
	GameControl.set_player(self)
	planet = get_node_or_null(planet_path)
	pathwright = get_node_or_null(pathwright_path)

	if not planet:
		push_error("Planet node not found")
	if not pathwright or not "is_inside" in pathwright:
		push_error("Pathwright node not found or missing is_inside()")

	arms_container = $ArmsContainer

func _physics_process(delta):
	# Set up_direction for move_and_slide to use custom gravity
	if planet:
		var gravity_dir = (planet.global_position - global_position).normalized()
		up_direction = -gravity_dir  # Tell Godot which way is "up"
		# Apply custom gravity
		velocity += gravity_dir * gravity_strength * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += up_direction * abs(JUMP_VELOCITY)  # Make sure it's positive
	
	# Horizontal movement - let Godot handle this naturally
	var direction = Input.get_axis("move_left", "move_right")
	var right_dir = Vector2(-up_direction.y, up_direction.x)
	var tangent_speed = velocity.dot(right_dir)

	if direction != 0:
		var desired_speed = direction * SPEED
		var accel = 10.0 if is_on_floor() else 4.0  # control snappiness
		tangent_speed = move_toward(tangent_speed, desired_speed, accel)
	else:
		tangent_speed = move_toward(tangent_speed, 0, 6.0)

	velocity = right_dir * tangent_speed + up_direction * velocity.dot(up_direction)
	
	# Rotate player to always face "up" relative to planet
	# Rotate player to always face "up" relative to planet
	if planet:
		if facing_right:
			rotation = up_direction.angle() + PI/2
		else:
			rotation = up_direction.angle() - PI/2  # Different rotation when flipped
	
	
	# Handle sprite flipping for left/right movement
	if direction > 0 and not facing_right:
		scale.x *= -1  # Back to flipping horizontally
		facing_right = true
	elif direction < 0 and facing_right:
		scale.x *= -1  # Back to flipping horizontally
		facing_right = false
	# Handle arm pointing
	# Let weapon/arm controller handle input & aiming
	arms_container.facing_right = facing_right
	
	move_and_slide()
	
	
