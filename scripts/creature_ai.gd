extends Node
class_name CreatureAI

@export var ai_tick_rate := 1.5
@export var shoot_distance := 400.0
@export var inout_area_path: NodePath  # Assign this to your local InOutCollisionArea

@export_range(0.0, 180.0) var min_jump_angle_deg := 45.0  # Considered a "good" minimum angle
@export_range(0.0, 180.0) var max_jump_angle_deg := 90.0  # Max angle we still consider for jumping
@export var jump_distance_limit := 300.0  # Max horizontal distance to target to consider jump
@export var jump_vertical_min := 30.0  # Min vertical difference required to even consider jumping
@export_range(0.0, 1.0) var jump_aggression := 1.0  # 0 = cautious jumper, 1 = jump-happy

var down_direction: Vector2 = Vector2.DOWN
var right_direction: Vector2 = Vector2.RIGHT

var pilot_vehicle: Node2D = null
var target: Node2D = null
var parent: Node = null
var time_accum := 0.0
var tick_interval := 1.0
var arms: CreatureArms = null
var los_target := false
var suppress_shooting := false
var inout_area: Node = null

var rng := RandomNumberGenerator.new()

func _ready():
	parent = get_parent()
	arms = parent.get_node_or_null("Model/Arms")

	var maybe_vehicle = parent.get_parent()
	while maybe_vehicle and maybe_vehicle != get_tree().root:
		if maybe_vehicle.has_method("set_move_input"):
			pilot_vehicle = maybe_vehicle
			maybe_vehicle.start_piloting(self)
			if parent is SGEntity:
				parent.is_static = true
			print("PILOT VEHICLE FOUND")
			break
		maybe_vehicle = maybe_vehicle.get_parent()

	if not parent:
		push_error("CreatureAI must be child of a Creature")
		return

	rng.seed = int(hash(parent.name)) % 100000000

	if inout_area_path != NodePath():
		inout_area = get_node_or_null(inout_area_path)
		if inout_area:
			inout_area.goatboy_entered_inner.connect(_on_target_went_inside)
			inout_area.goatboy_exited_inner.connect(_on_target_left_inside)

	_schedule_next_tick()

func _process(delta):
	if not parent:
		return

	down_direction = -parent.up_direction
	right_direction = Vector2(-down_direction.y, down_direction.x)

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
	var vertical_delta := 0.0
	var global_y_diff := 0.0

	if player:
		target = player
		dist = parent.global_position.distance_to(player.global_position)

		var to_target = player.global_position - parent.global_position
		vertical_delta = to_target.dot(down_direction)
		global_y_diff = player.global_position.y - parent.global_position.y

	return {
		"target": target,
		"distance": dist,
		"vertical_to_target": vertical_delta,
		"global_y_difference": global_y_diff
	}

func decide(perception: Dictionary) -> Dictionary:
	var actions := {}
	los_target = false

	if perception.target and perception.distance < 1000:
		# Line-of-sight check
		if perception.distance < shoot_distance:
			var space_state = parent.get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(parent.global_position, perception.target.global_position)
			query.collision_mask = 1
			query.exclude = [parent]
			var result = space_state.intersect_ray(query)
			los_target = result.is_empty()

		# Angular movement
		var center = parent.planet.global_position
		var angle_self = (parent.global_position - center).angle()
		var angle_target = (perception.target.global_position - center).angle()
		var delta_angle = wrapf(angle_target - angle_self, -PI, PI)
		
		# we need to calculate vertical distance to target relative to creature or vehicle
		var my_relative_body = pilot_vehicle if pilot_vehicle else parent
		
		## Jump inclination logic
		var to_target = perception.target.global_position - parent.global_position
		var local_up = my_relative_body.up_direction
		var local_right = Vector2(-local_up.y, local_up.x)
		var vertical = to_target.dot(local_up)
		actions["move_input"] = Vector2(signf(delta_angle), signf(vertical))
		
	return actions

func act(actions: Dictionary):
	if pilot_vehicle:
		if actions.has("move_input") and pilot_vehicle.has_method("set_move_input"):
			print("SET MOVE OK")
			pilot_vehicle.set_move_input(actions["move_input"])
		if actions.has("jump_strength") and pilot_vehicle.has_method("trigger_jump"):
			pilot_vehicle.trigger_jump(actions["jump_strength"])
	else:
		if actions.has("move_input"):
			parent.move_input = actions["move_input"]
		if actions.has("jump_strength"):
			parent.trigger_jump(actions["jump_strength"])

# ----- Callbacks from InOut -----

func _on_target_went_inside(body: Node):
	if body == target:
		suppress_shooting = true

func _on_target_left_inside(body: Node):
	if body == target:
		suppress_shooting = false
