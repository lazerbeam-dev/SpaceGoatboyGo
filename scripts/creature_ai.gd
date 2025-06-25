extends Node
class_name CreatureAI

@export var ai_tick_rate := 1.5

var target: Node2D = null
var parent: Node = null
var time_accum := 0.0
var tick_interval := 1.0

func _ready():
	parent = get_parent()
	if not parent:
		push_error("CreatureAI must be child of a Creature")
		return
	_schedule_next_tick()

func _process(delta):
	if not parent:
		return

	time_accum += delta
	if time_accum >= tick_interval:
		time_accum = 0.0
		_schedule_next_tick()
		_run_ai_tick()

func _schedule_next_tick():
	var jitter := randf_range(-0.2, 0.2)
	tick_interval = max(0.05, ai_tick_rate * (1.0 + jitter))

func _run_ai_tick():
	var perception = perceive()
	var decision = decide(perception)
	act(decision)

# ----- EXTENSION POINTS -----

func perceive() -> Dictionary:
	var player = GameControl.player
	var dist = INF
	if player:
		target = player
		dist = parent.global_position.distance_to(player.global_position)
	return {
		"target": target,
		"distance": dist
	}

func decide(perception: Dictionary) -> Dictionary:
	var actions := {}
	if perception.target and perception.distance < 1000:
		var center = parent.planet.global_position
		var angle_self = (parent.global_position - center).angle()
		var angle_target = (perception.target.global_position - center).angle()
		var delta_angle = wrapf(angle_target - angle_self, -PI, PI)
		actions["move_input"] = signf(delta_angle)
	return actions

func act(actions: Dictionary):
	if actions.has("move_input"):
		parent.move_input = actions["move_input"]
