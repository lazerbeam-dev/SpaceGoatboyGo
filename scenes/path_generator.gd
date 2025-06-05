@tool
extends Node2D
class_name Pathwright

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

@onready var path_node: Path2D = $GeneratedPath
var rng := RandomNumberGenerator.new()

# Stores info for each segment: { from: Vector2, to: Vector2, wall: bool }
var segment_info: Array = []

func generate_path():
	#assert(typeof(step_amplitude) == TYPE_FLOAT, "step_amplitude is uninitialized")
	#assert(typeof(step_frequency) == TYPE_FLOAT, "step_frequency is uninitialized")
	print("==> Generating circular wavy path")
	clear_path()
	segment_info.clear()

	rng.seed = seed
	print("Seed set:", seed)

	var curve := Curve2D.new()
	if not path_node:
		print("ERROR: path_node is null!")
		return

	path_node.curve = curve
	print("Curve assigned to path_node")

	var points := []

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
		var point = Vector2(x, y)
		points.append(point)
		curve.add_point(point)
		print("  Point", i, ":", point)

	# Close loop
	points.append(points[0])
	curve.add_point(points[0])

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update...")
		renderer.update_render()
	else:
		print("No renderer found or update_render method missing")

func clear_path():
	print("==> Clearing path")

	if path_node and path_node.curve:
		path_node.curve.clear_points()
		print("Path curve cleared")
	else:
		print("WARNING: path_node or its curve is null")

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update after clear")
		renderer.update_render()
	else:
		print("No renderer to update after clear")
		
