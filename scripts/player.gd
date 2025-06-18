extends CharacterBody2D
#class_name Creature

#const SPEED := 260.0
#const JUMP_VELOCITY := -500.0
#const COYOTE_TIME := 0.15
#
#@export var planet_path: NodePath = "../Planet"
#@export var pathwright_path: NodePath = "../Pathwright"
#
#var gravity_strength := 980.0
#var facing_right := true
#var planet: Node2D
#var arms_container: Node2D
#var pathwright: Node = null
#
## Controlled externally
#var move_input: float = 0.0
#var jump_intent: bool = false
#
## Internals
#var time_since_grounded: float = 0.0
#var jump_was_consumed: bool = false
#
#func _ready() -> void:
	#GameControl.set_player(self)
	#planet = get_node_or_null(planet_path)
	#pathwright = get_node_or_null(pathwright_path)
#
	#if not planet:
		#push_error("Planet node not found")
#
	#arms_container = $ArmsContainer
#
#func _physics_process(delta: float) -> void:
	#if not planet:
		#return
#
	#var gravity_dir: Vector2 = (planet.global_position - global_position).normalized()
	#up_direction = -gravity_dir
	#velocity += gravity_dir * gravity_strength * delta
#
	## Track grounded state
	#if is_on_floor():
		#if time_since_grounded > 0.0:
			#jump_was_consumed = false  # Reset on landing
		#time_since_grounded = 0.0
	#else:
		#time_since_grounded += delta
#
	## Jump logic (buffering handled externally)
	#if not jump_was_consumed and jump_intent and time_since_grounded <= COYOTE_TIME:
		#velocity += up_direction * abs(JUMP_VELOCITY)
		#jump_was_consumed = true
#
	#var right_dir: Vector2 = Vector2(-up_direction.y, up_direction.x)
	#var tangent_speed: float = velocity.dot(right_dir)
#
	#if move_input != 0.0:
		#var desired_speed: float = move_input * SPEED
		#var accel: float = 10.0 if is_on_floor() else 4.0
		#tangent_speed = move_toward(tangent_speed, desired_speed, accel)
	#else:
		#tangent_speed = move_toward(tangent_speed, 0.0, 6.0)
#
	#velocity = right_dir * tangent_speed + up_direction * velocity.dot(up_direction)
#
	#rotation = up_direction.angle() + (PI / 2 if facing_right else -PI / 2)
#
	#if move_input > 0.0 and not facing_right:
		#scale.x *= -1
		#facing_right = true
	#elif move_input < 0.0 and facing_right:
		#scale.x *= -1
		#facing_right = false
#
	#arms_container.facing_right = facing_right
	#move_and_slide()
