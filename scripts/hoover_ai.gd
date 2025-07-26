extends Node
class_name HooverSeekerAI

@export var ai_tick_rate := 0.2  # Seconds between thinking updates
@export var approach_distance := 30.0  # Distance at which to attach tentacle
@export var tentacle_path: NodePath  # Optional: path to TentaclePath node
@export var target_node: Node2D  # Optional: overrides collar targeting

var parent: Node2D = null
var tentacle: TentaclePath = null
var time_accum := 0.0
var tick_interval := 1.0
var has_attached := false

func _ready():
	parent = get_parent()

	if tentacle_path != NodePath():
		var maybe_tentacle = get_node_or_null(tentacle_path)
		if maybe_tentacle is TentaclePath:
			tentacle = maybe_tentacle
			tentacle.destination = null
		else:
			push_warning("HooverSeekerAI: TentaclePath invalid or not a TentaclePath node")

	_schedule_next_tick()

func _process(delta):
	if not parent or has_attached:
		return

	time_accum += delta
	if time_accum >= tick_interval:
		time_accum = 0.0
		_schedule_next_tick()
		_run_ai_tick()

func _schedule_next_tick():
	var jitter := randf_range(-0.1, 0.1)
	tick_interval = max(0.05, ai_tick_rate * (1.0 + jitter))

func _run_ai_tick():
	### NOTE TO FUTURE SELF THIS NEEDS FIXING, DONT RELY ON PARENT TO SET MOVE INPUT TO THE RIGHT THING CAUSE WE REPARENT
	
	var target :Node2D= target_node if is_instance_valid(target_node) else Utils.get_active_collar()
	if not is_instance_valid(target):
		#parent.move_input = Vector2.ZERO
		return

	var to_target = target.global_position - parent.global_position
	var distance = to_target.length()

	if distance <= approach_distance:
		_attach_to_target(target)
		#parent.move_input = Vector2.ZERO
		has_attached = true
	else:
		pass
		#parent.move_input = to_target.normalized()

func _attach_to_target(target: Node2D) -> void:
	if tentacle and is_instance_valid(target):
		tentacle.destination = target
		print("HooverSeekerAI: Tentacle attached to", target.name)
