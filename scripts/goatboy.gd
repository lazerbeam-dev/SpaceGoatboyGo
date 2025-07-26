extends Creature
class_name Goatboy

var goat_mode_held := false
var last_animation := ""
var base_speed := 0

var is_flying_with_rocket_boots: bool = false 
var grounded_time := 0.0
var fallback_walk_playing := false
var idle_anim_time := 0.0

@export var goatboy_speed:= 1200
func _ready():
	super._ready()
	base_speed = speed  # now captures whatever the actual export or game-assigned value is
func _physics_process(delta):
	super._physics_process(delta)
	#print("my move input", move_input)

	creature_animate()
	if piloted_vehicle and is_instance_valid(piloted_vehicle):
		print("piloting vehicle MI:", move_input)
		piloted_vehicle.move_input = move_input
		# === Fallback Walk Trigger (Airborne or Grounded) ===
	var is_idle :bool= not legs_animator.playback_active and not goat_mode_held

	if is_idle:
		idle_anim_time += delta
		if idle_anim_time >= 0.5 and not fallback_walk_playing:
			if legs_animator and legs_animator.has_animation("walk"):
				legs_animator.play("walk")
				legs_animator.playback_active = true
				fallback_walk_playing = true
	else:
		idle_anim_time = 0.0
		fallback_walk_playing = false

func creature_animate():
	if is_dead or not legs_animator:
		return
	
	var current_anim := legs_animator.current_animation
	var target_anim := ""

	if goat_mode_held and is_flying_with_rocket_boots:
		target_anim = "goatmode_flying"
	elif goat_mode_held:
		if abs(move_input.x) > 0.01 :
			target_anim = "goatmode"
		else: target_anim = "goatmode_static"
	elif abs(move_input.x) > 0.1 && is_on_floor():
		target_anim = "walk"
	else:
		pass

	if target_anim:
		if current_anim != target_anim or not legs_animator.playback_active:
			if legs_animator.has_animation(target_anim):
				legs_animator.play(target_anim)
				legs_animator.playback_active = true
			else:
				legs_animator.playback_active = false
				print("Warning: Missing animation for " + target_anim)
	else:
		if current_anim in ["walk", "goatmode", "goatmode_flying"]:
			legs_animator.playback_active = false

	if (last_animation == "goatmode" or last_animation == "goatmode_flying") and current_anim == "walk":
		kick_up_from_goat_mode()

	last_animation = current_anim

func trigger_goat_mode(enable: bool = true):
	if goat_mode_held == enable:
		return
	goat_mode_held = enable

	if enable:
		activate_goat_mode_area()
	else:
		deactivate_goat_mode_area()
	
	if not enable:
		is_flying_with_rocket_boots = false

func kick_up_from_goat_mode():
	if not planet:
		return
	var up_dir := -(planet.global_position - global_position).normalized()
	global_position += up_dir * 16

func activate_goat_mode_area():
	speed =goatboy_speed

func deactivate_goat_mode_area():
	speed = base_speed

func set_flying_with_rocket_boots(flying: bool):
	is_flying_with_rocket_boots = flying
