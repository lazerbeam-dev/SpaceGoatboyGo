extends SGEntity
class_name Creature

@export var planet_path: NodePath
@export var speed: float = 260.0
@export var jump_velocity: float = -300.0
@export var acceleration: float = 1000.0
@export var air_acceleration_ratio: float = 0.5
@export var coyote_time: float = 0.15
@export var death_delay: float = 1.0
@export var facing_right := true
@export var max_velocity := Vector2(10000, 10000)
func can_jump() -> bool:
	return coyote_timer <= coyote_time and not is_stunned

var jump_strength_ratio: float = 1.0

var jump_requested: bool = false
var coyote_timer := 0.0
var is_dead := false
var death_timer := 0.0
var is_dying := false
var did_jump := false
var externally_controlled := false

var is_stunned := false
var stun_timer := 0.0
var stored_move_input := Vector2.ZERO
@onready var model: Node = $Model
@onready var arms: CreatureWeaponController = model.get_node_or_null("Torso/Arms") if model else null
@onready var legs_animator: AnimationPlayer = get_node_or_null("LegsAnimator")

func _ready():
	super._ready()
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
		push_error("Creature: Planet not found via path or Game/Planet search.")
		return
	var gravity_dir = (planet.global_position - global_position).normalized()
	var up_dir = -gravity_dir
	up_direction = up_dir
	motile = true

func _physics_process(delta):
	if not planet or is_dead:
		return
	super._physics_process(delta)
	face_movement()
	if is_static:
		return
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			#move_input = stored_move_input
			print("Creature: ", name, " recovered from stun")

	if is_dying:
		death_timer += delta
		if death_timer >= death_delay:
			is_dead = true
			is_dying = false
			#move_input = Vector2.ZERO
			jump_requested = false
			queue_free() 

	var gravity_dir = (planet.global_position - global_position).normalized()
	var up_dir = -gravity_dir
	up_direction = up_dir
	velocity += gravity_dir * gravity_strength * delta

	if is_on_floor() and velocity.dot(up_dir) <= 0:
		coyote_timer = 0.0
	else:
		coyote_timer += delta

	if jump_requested and coyote_timer <= coyote_time and not is_stunned:
		var strength := 0.25 + pow(jump_strength_ratio, 0.7) * 0.9
		velocity += up_dir * abs(jump_velocity) * strength
		coyote_timer = coyote_time + 1.0
		did_jump = true
		jump_requested = false

	var right_dir = Vector2(-up_dir.y, up_dir.x)
	var tangent_speed = velocity.dot(right_dir)
	var effective_move_input = 0.0 if is_stunned else move_input.x
	var desired_speed = effective_move_input * speed
	var accel = acceleration if is_on_floor() else acceleration * air_acceleration_ratio
	tangent_speed = move_toward(tangent_speed, desired_speed, accel * delta)
	velocity = right_dir * tangent_speed + up_dir * velocity.dot(up_dir)

	face_movement()

	velocity.x = clamp(velocity.x, -max_velocity.x, max_velocity.x)
	velocity.y = clamp(velocity.y, -max_velocity.y, max_velocity.y)
	rotation = up_dir.angle() + PI / 2
	
	creature_animate()
	move_and_slide()
func face_movement():
	if not is_stunned:
		if move_input.x > 0:
			facing_right = true
			if arms:
				arms.facing_right = true
		elif move_input.x < 0:
			facing_right = false
			if arms:
				arms.facing_right = false

	if model:
		model.scale.x = abs(model.scale.x) * (1 if facing_right else -1)
func creature_animate():
	if not legs_animator or is_static:
		return

	if not is_on_floor():
		if legs_animator.current_animation != "jump":
			legs_animator.play("jump")
		legs_animator.playback_active = true
	elif abs(move_input) > 0.1:
		if legs_animator.current_animation != "walk":
			legs_animator.play("walk")
		legs_animator.playback_active = true
	else:
		if legs_animator.current_animation == "walk":
			legs_animator.playback_active = false

func set_move_input(dir: float):
	if is_dead:
		return
	var new_input = clampf(dir, -1.0, 1.0)
	if is_stunned:
		stored_move_input = Vector2(new_input, 0)
	else:
		move_input = Vector2(new_input, 0)

func trigger_jump(charge_ratio: float = 1.0):
	if is_dead or is_stunned or is_static:
		return
	jump_requested = true
	jump_strength_ratio = clampf(charge_ratio, 0.0, 1.0)

func set_gravity_scale(tog: float):
	gravity_strength = tog

func set_ext(ext: bool):
	externally_controlled = ext

func apply_stun(duration: float):
	if is_dead or is_static:
		return
	is_stunned = true
	stun_timer = duration
	stored_move_input = move_input
	#move_input = Vector2.ZERO
	jump_requested = false
	print("Creature: ", name, " stunned for ", duration, " seconds")

func is_currently_stunned() -> bool:
	return is_stunned

func die(_custom_delay: float = -1.0):
	is_dying = true

func revive():
	is_dead = false
	is_dying = false
	death_timer = 0.0
	is_stunned = false
	stun_timer = 0.0

func get_move_input():
	return move_input
