extends Node2D
class_name Tentacle2D

@export var segment_count := 8
@export var segment_length := 20.0
@export var reach_speed := 0.2
@export var damping := 0.1
@export var target_path: NodePath

var points: Array[Vector2] = []
var velocities: Array[Vector2] = []

var target: Node2D

@onready var line := $Line2D

func _ready():
	points.resize(segment_count + 1)
	velocities.resize(segment_count + 1)
	for i in range(points.size()):
		points[i] = Vector2(segment_length * i, 0)
		velocities[i] = Vector2.ZERO

	target = get_node_or_null(target_path)

func _process(delta):
	if not is_instance_valid(target):
		return

	var base := global_position
	var tgt := target.global_position - base
	solve_fabrik(tgt)
	smooth_points(delta)
	draw_tentacle()

func solve_fabrik(tgt: Vector2):
	var lengths := []
	for i in range(segment_count):
		lengths.append(segment_length)

	var total_length = segment_length * segment_count
	var base = Vector2.ZERO
	var dist = tgt.length()

	# Stretch to max if out of reach
	if dist > total_length:
		for i in range(points.size()):
			points[i] = base.lerp(tgt, float(i) / segment_count)
		return

	# Initial guess
	points[0] = base
	for i in range(1, points.size()):
		points[i] = points[i - 1] + (points[i] - points[i - 1]).normalized() * lengths[i - 1]

	var tolerance = 0.5
	var max_iters = 8

	for _i in range(max_iters):
		# Backward
		points[points.size() - 1] = tgt
		for i in range(points.size() - 2, -1, -1):
			var dir = (points[i] - points[i + 1]).normalized()
			points[i] = points[i + 1] + dir * lengths[i]

		# Forward
		points[0] = base
		for i in range(1, points.size()):
			var dir = (points[i] - points[i - 1]).normalized()
			points[i] = points[i - 1] + dir * lengths[i - 1]

		if (points[points.size() - 1] - tgt).length() < tolerance:
			break

func smooth_points(delta: float):
	for i in range(points.size()):
		var world_target = to_global(points[i])
		var current = to_global(points[i])  # You can cache world positions for physics
		var v = (world_target - current) * reach_speed
		velocities[i] = velocities[i].lerp(v, damping)
		points[i] = to_local(to_global(points[i]) + velocities[i] * delta)

func draw_tentacle():
	line.clear_points()
	for p in points:
		line.add_point(p)
