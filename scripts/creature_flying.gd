extends SGEntity
class_name FloaterCreature

@export var planet_path: NodePath
@export var speed: float = 220.0
@export var acceleration: float = 800.0
@export var drag: float = 0.8
@export var death_delay: float = 1.0
@export var facing_right := true
var is_dead := false
var death_timer := 0.0
var is_dying := false
var externally_controlled := false

var is_stunned := false
var stun_timer := 0.0
var stored_move_input := Vector2.ZERO

@onready var model: Node = $Model
@onready var arms: CreatureWeaponController = model.get_node_or_null("Torso/Arms") if model else null

func _ready():
	planet = get_node_or_null(planet_path)
	if not planet:
		var current = self
		while current:
			if current.name == "Game":
				planet = current.get_node_or_null("Planet")
				if planet:
					break
			current = current.get_parent()
	if not planet:
		push_error("Floater: Planet not found via path or Game/Planet search.")
	motile = true

# FloaterCreature's _physics_process (modified section)
func _physics_process(delta: float) -> void:
	if not planet or is_dead:
		return
	if is_static:
		return
	super._physics_process(delta)
	# ... (stun and dying logic) ...

	# Rotational gravity alignment
	var gravity_dir := (planet.global_position - global_position).normalized()
	var up_dir := -gravity_dir # This is the global radial "up"
	up_direction = up_dir
	var right_dir = Vector2(-up_dir.y, up_dir.x) # This is the global tangential "right"

	rotation = right_dir.angle() # Creature aligns its LOCAL X-axis with global right_dir, LOCAL Y-axis with global up_dir
	
	if gravity_strength > 0.0: # If there's gravity, it will pull. For flying, this is likely 0.
		velocity += gravity_dir * gravity_strength * delta
	
	var effective_input := Vector2.ZERO if is_stunned else move_input # move_input from AI: (x_input, y_input)

	# --- CRITICAL CHANGE HERE ---
	# Calculate target velocity based on LOCAL input directions
	var desired_local_direction = Vector2.ZERO
	if effective_input.length_squared() > 0.0: # Avoid normalizing a zero vector
		# effective_input.x controls movement along right_dir (tangential)
		# effective_input.y controls movement along up_dir (radial)
		desired_local_direction = right_dir * effective_input.x + up_dir * effective_input.y
		desired_local_direction = desired_local_direction.normalized() # Normalize the combined local direction

	var target_velocity :Vector2= desired_local_direction * speed

	velocity = velocity.lerp(target_velocity, clamp(acceleration * delta, 0.0, 1.0))
	velocity *= pow(drag, delta)

	if effective_input.length_squared() > 0.0:
		var dot_product_with_right = desired_local_direction.dot(right_dir)
		var new_facing_right = dot_product_with_right >= 0
		facing_right = new_facing_right  # update persistent state

		if model:
			model.scale.x = abs(model.scale.x) * (1 if facing_right else -1)
		if arms:
			arms.facing_right = facing_right
	else:
		# Keep using previous facing_right
		if model:
			model.scale.x = abs(model.scale.x) * (1 if facing_right else -1)
		if arms:
			arms.facing_right = facing_right


	move_and_slide()
func set_move_axis(dir: Vector2) -> void:
	if is_dead or is_static:
		return
	if is_stunned:
		stored_move_input = dir
	else:
		move_input = dir.normalized()

func set_ext(ext: bool) -> void:
	externally_controlled = ext

func apply_stun(duration: float) -> void:
	if is_dead or is_static:
		return
	is_stunned = true
	stun_timer = duration
	stored_move_input = move_input
	#move_input = Vector2.ZERO
	print("Floater: ", name, " stunned for ", duration, " seconds")

func is_currently_stunned() -> bool:
	return is_stunned

func die(_custom_delay: float = -1.0) -> void:
	is_dying = true

func revive() -> void:
	is_dead = false
	is_dying = false
	death_timer = 0.0
	is_stunned = false
	stun_timer = 0.0

func get_move_input() -> Vector2:
	return move_input
