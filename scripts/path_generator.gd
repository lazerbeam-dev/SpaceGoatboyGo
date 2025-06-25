@tool
extends Node2D
class_name Pathwright

@export var path_node_path: NodePath = "GeneratedPath"
@export var radius := 1000.0
@export var section_count := 100
@export var auto_generate := false:
	set(value):
		auto_generate = value
		if Engine.is_editor_hint() and value:
			print("Auto-generate triggered from editor")
			generate_path()

@export var seed := 0
@export var frequency_1 := 4.0
@export var frequency_2 := 2.0
@export var amplitude_1 := 100.0
@export var amplitude_2 := 60.0
@export var noise_strength := 40.0
@export var step_amplitude := 160.0
@export var step_frequency := 2.0
@export var step2_amplitude := 40.0
@export var step2_frequency := 10.0

@export var max_climb_angle := 45.0  # degrees
@export var clear_path_button := false:
	set(value):
		clear_path_button = false
		clear_path()

var rng := RandomNumberGenerator.new()
var segment_info: Array = []

func _ready():
	if Engine.is_editor_hint() and auto_generate:
		generate_path()

func get_path_node() -> Node:
	var node := get_node_or_null(path_node_path)
	if not node or not (node is Path2D or node is Line2D):
		push_error("Pathwright: path_node must be a Path2D or Line2D")
		return null
	return node

func generate_path():
	print("==> Generating circular wavy path")
	clear_path()
	segment_info.clear()

	rng.seed = seed
	print("Seed set:", seed)

	var raw_points: Array[Vector2] = []

	for i in range(section_count):
		var theta := (TAU / section_count) * i

		var wave = sin(theta * frequency_1) * amplitude_1 \
			 + sin(theta * frequency_2) * amplitude_2 \
			 + rng.randf_range(-noise_strength, noise_strength)

		var step_wave = step_amplitude * sign(sin(theta * step_frequency))
		var step_wave2 = step2_amplitude * sign(sin(theta * step2_frequency))

		var r = radius + wave + step_wave + step_wave2

		var x = cos(theta) * r
		var y = sin(theta) * r
		raw_points.append(Vector2(x, y))

	# --- Smart smoothing pass ---
	var angle_threshold_deg := 25.0
	var smoothed_points: Array[Vector2] = []

	for i in range(raw_points.size()):
		var prev: Vector2 = raw_points[(i - 1 + raw_points.size()) % raw_points.size()]
		var curr: Vector2 = raw_points[i]
		var next: Vector2 = raw_points[(i + 1) % raw_points.size()]

		var v1: Vector2 = (curr - prev).normalized()
		var v2: Vector2 = (next - curr).normalized()
		var angle: float = rad_to_deg(v1.angle_to(v2))

		var is_cliff: bool = abs(angle) >= max_climb_angle
		var is_smoothable: bool = abs(angle) < angle_threshold_deg

		if is_cliff:
			smoothed_points.append(curr)
		elif is_smoothable:
			smoothed_points.append((prev + curr + next) / 3.0)
		else:
			smoothed_points.append(curr)

	if smoothed_points.size() > 0:
		smoothed_points[smoothed_points.size() - 1] = smoothed_points[0]

	var path_node := get_path_node()
	if not path_node:
		return

	if path_node is Path2D:
		var curve := Curve2D.new()
		for point in smoothed_points:
			curve.add_point(point)
		path_node.curve = curve
		print("Curve assigned to Path2D")
	elif path_node is Line2D:
		path_node.points = smoothed_points
		print("Points assigned to Line2D")

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update...")
		renderer.update_render()
	else:
		print("No renderer found or update_render method missing")

func clear_path():
	print("==> Clearing path")
	var path_node := get_path_node()
	if not path_node:
		return

	if path_node is Path2D and path_node.curve:
		path_node.curve.clear_points()
		print("Path2D curve cleared")
	elif path_node is Line2D:
		path_node.points.clear()
		print("Line2D points cleared")
	else:
		print("WARNING: Path node is missing or invalid")

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update after clear")
		renderer.update_render()
	else:
		print("No renderer to update after clear")
