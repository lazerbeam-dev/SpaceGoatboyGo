extends Node
class_name CreatureAI

@export var ai_tick_rate := 1.5
@export var shoot_distance := 400.0
@export var inout_area_path: NodePath  # Assign this to your local InOutCollisionArea

var target: Node2D = null
var parent: Node = null
var time_accum := 0.0
var tick_interval := 1.0
var arms: CreatureArms = null
var los_target := false
var suppress_shooting := false
var inout_area: Node = null

func _ready():
	parent = get_parent()
	arms = parent.get_node_or_null("Model/Arms")
	if not parent:
		push_error("CreatureAI must be child of a Creature")
		return

	if inout_area_path != NodePath():
		inout_area = get_node_or_null(inout_area_path)
		if inout_area:
			inout_area.goatboy_entered_inner.connect(_on_target_went_inside)
			inout_area.goatboy_exited_inner.connect(_on_target_left_inside)

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
	var dist := INF
	if player:
		target = player
		dist = parent.global_position.distance_to(player.global_position)
	return {
		"target": target,
		"distance": dist
	}

func decide(perception: Dictionary) -> Dictionary:
	var actions := {}

	los_target = false

	if perception.target and perception.distance < 1000:
		if perception.distance < shoot_distance:
			var space_state = parent.get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(parent.global_position, perception.target.global_position)
			query.collision_mask = 1
			query.exclude = [parent]
			var result = space_state.intersect_ray(query)
			los_target = result.is_empty()

		var center = parent.planet.global_position
		var angle_self = (parent.global_position - center).angle()
		var angle_target = (perception.target.global_position - center).angle()
		var delta_angle = wrapf(angle_target - angle_self, -PI, PI)
		actions["move_input"] = signf(delta_angle)

	return actions

func act(actions: Dictionary):
	if actions.has("move_input"):
		parent.move_input = actions["move_input"]

	if target and arms and not suppress_shooting:
		var dist = parent.global_position.distance_to(target.global_position)
		if dist < shoot_distance and los_target:
			arms.use_manual_aim = true
			arms.manual_aim_target = target.global_position
		else:
			arms.use_manual_aim = false
	else:
		if arms:
			arms.use_manual_aim = false

# ----- Callbacks from InOut -----

func _on_target_went_inside(body: Node):
	if body == target:
		suppress_shooting = true

func _on_target_left_inside(body: Node):
	if body == target:
		suppress_shooting = false
