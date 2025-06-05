# Creature.gd
extends CharacterBody2D
class_name Creature

@export var planet_path: NodePath
@export var gravity_strength: float = 980.0
@export var speed: float = 260.0
@export var jump_velocity: float = -300.0
@export var health: float = 10

var planet: Node2D
var facing_right := true
var move_input: float = 0.0
var jump_input: bool = false
var natural_model_scale = 1

func _ready():
	planet = get_node_or_null(planet_path)
	if not planet:
		push_error("Planet not found")
	natural_model_scale = $Sprite2D.scale

func take_damage(amount: float, type: String = ""):
	health -= amount
	if health <= 0:
		queue_free()  # Or PoolManager.free() if pooled

func _physics_process(delta):
	if not planet: 
		return
	
	var gravity_dir = (planet.global_position - global_position).normalized()
	var up_dir = -gravity_dir
	up_direction = up_dir
	
	velocity += gravity_dir * gravity_strength * delta
	
	# Handle jumping
	if jump_input and is_on_floor():
		velocity += up_dir * abs(jump_velocity)
	
	# Tangential movement
	var right_dir = Vector2(-up_dir.y, up_dir.x)
	var tangent_speed = velocity.dot(right_dir)
	var desired_speed = move_input * speed
	var accel = 10.0 if is_on_floor() else 4.0
	tangent_speed = move_toward(tangent_speed, desired_speed, accel)
	
	velocity = right_dir * tangent_speed + up_dir * velocity.dot(up_dir)
	
	# Log movement direction and flip sprite
	if move_input > 0:
		print("Moving clockwise around planet")
		$Sprite2D.scale.x = natural_model_scale.x
	elif move_input < 0:
		print("Moving anti-clockwise around planet")
		$Sprite2D.scale.x = -natural_model_scale.x
	
	# Rotate creature
	rotation = up_dir.angle() + (PI/2 if facing_right else -PI/2)
	
	var collision = move_and_slide()
	#if collision:
		#velocity = Vector2.ZERO
	
	# Optional animation hook
	#_on_animate(move_input, jump_input)

#func _on_animate(dir, jump):
	#if is_on_floor():
		#print("anim: idle" if dir == 0 else "anim: run")
	#else:
		#print("anim: jump")
