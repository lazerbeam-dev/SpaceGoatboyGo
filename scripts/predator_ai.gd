extends Node
class_name PredatorAI

enum PresenceState { NO_GOATBOY, GOATBOY_ATTACHED }
enum GoatboyTreatment { NORMAL, PUNISH, KILL }

@export var vertical_offset := 900.0
@export var backward_offset := 180.0
@export var approach_tolerance := 40.0
@export var max_pursuit_speed := 1.0

@export var vacuum_arms: Array[NodePath] = []

var presence_state := PresenceState.NO_GOATBOY
var treatment_mode := GoatboyTreatment.NORMAL

var target: Node2D = null
var floater: FloaterCreature
var vacuum_arm_refs: Array[Node] = []

func _ready():
	floater = get_parent() as FloaterCreature
	if not floater:
		push_error("PredatorAI must be a child of a FloaterCreature")

	for path in vacuum_arms:
		var arm = get_node_or_null(path)
		if arm:
			vacuum_arm_refs.append(arm)

	set_process(true)

func _process(delta: float):
	if is_instance_valid(Utils.get_active_collar()):
		target = Utils.get_active_collar()

		if is_instance_valid(target):
			presence_state = PresenceState.GOATBOY_ATTACHED
		else:
			presence_state = PresenceState.NO_GOATBOY
	else:
		return

	match presence_state:
		PresenceState.GOATBOY_ATTACHED:
			match treatment_mode:
				GoatboyTreatment.NORMAL:
					_update_positioning()
				GoatboyTreatment.PUNISH:
					# placeholder for punish behavior
					_update_positioning()
				GoatboyTreatment.KILL:
					# placeholder for kill behavior
					_update_positioning()
		PresenceState.NO_GOATBOY:
			# Follow previous goatboy or return to base or idle
			_update_positioning()

func _update_positioning():
	if not is_instance_valid(target) or not is_instance_valid(floater) or not is_instance_valid(floater.planet):
		return

	var gravity_dir := (floater.planet.global_position - target.global_position).normalized()
	var up := -gravity_dir
	var right := Vector2(-up.y, up.x)

	var facing_right := true
	var collar_node = target.get_node_or_null("CollarCreatureControl")
	if collar_node and collar_node.has_method("is_facing_right"):
		facing_right = collar_node.is_facing_right()
	elif target.has_method("get_facing_right"):
		facing_right = target.get_facing_right()

	var dir_backward = -right if facing_right else right
	var local_offset = up * vertical_offset + dir_backward * backward_offset
	var desired_position = target.global_position + local_offset
	var to_target = desired_position - floater.global_position

	if to_target.length() > approach_tolerance:
		var dir = to_target.normalized()
		floater.set_move_axis(dir * max_pursuit_speed)
	else:
		floater.set_move_axis(Vector2.ZERO)

# === Vacuum Arm Control ===

func set_vacuum_arms_follow_mode():
	for arm in vacuum_arm_refs:
		if not is_instance_valid(arm):
			continue
		if arm.get_parent() != self:
			var old_pos = arm.global_position
			add_child(arm)
			arm.global_position = old_pos
		arm.set_process(false)
		arm.set_physics_process(false)
		if arm.has_method("set_active"):
			arm.set_active(false)

func set_vacuum_arms_release_mode():
	for arm in vacuum_arm_refs:
		if not is_instance_valid(arm):
			continue
		arm.set_process(true)
		arm.set_physics_process(true)
		if arm.has_method("set_active"):
			arm.set_active(true)
