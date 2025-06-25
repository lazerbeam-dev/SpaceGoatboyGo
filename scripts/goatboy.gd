extends Creature
class_name Goatboy

var goat_mode_held := false
var last_animation := ""

func _physics_process(delta):
	super._physics_process(delta)

	if is_dead or not legs_animator:
		return

	var current_anim = legs_animator.current_animation

	# GOAT MODE active
	if goat_mode_held:
		if current_anim != "goatmode" and legs_animator.has_animation("goatmode"):
			legs_animator.play("goatmode")
		legs_animator.playback_active = true

	# Revert to walking if goat mode released
	elif abs(move_input) > 0.1:
		if current_anim != "walk":
			legs_animator.play("walk")
		legs_animator.playback_active = true

	else:
		if current_anim in ["walk", "goatmode"]:
			legs_animator.playback_active = false

	# Detect animation transition from goatmode to walk
	if last_animation == "goatmode" and current_anim == "walk":
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

func kick_up_from_goat_mode():
	if not planet:
		return
	var up_dir := -(planet.global_position - global_position).normalized()
	global_position += up_dir * 16 # Adjust as needed

func activate_goat_mode_area():
	pass

func deactivate_goat_mode_area():
	pass
