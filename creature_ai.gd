extends Node
class_name CreatureAI

var target: Node2D = null
var parent: Node = null

func _ready():
	parent = get_parent()
	if not parent:
		push_error("CreatureAI must be child of a Creature")

func _process(_delta):
	if not parent:
		return

	if target == null and GameControl.player != null:
		target = GameControl.player
		print("[CreatureAI] Target acquired: %s" % target.name)

	if not target:
		print("[CreatureAI] Waiting for target...")
		return

	if not parent.planet:
		print("[CreatureAI] Missing planet reference on parent")
		return

	var center = parent.planet.global_position

	# Get angles of creature and target around the planet
	var angle_self = (parent.global_position - center).angle()
	var angle_target = (target.global_position - center).angle()

	# Compute smallest angular difference
	var delta_angle = wrapf(angle_target - angle_self, -PI, PI)

	# Decide direction around the arc
	var move_dir = signf(delta_angle)

	parent.move_input = move_dir
