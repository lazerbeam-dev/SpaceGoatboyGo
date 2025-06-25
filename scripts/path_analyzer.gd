@tool
extends Node2D
class_name PathAnalyzerTool

@export var curve_path: NodePath
@export var max_climb_angle := 45.0
@export var center := Vector2.ZERO
@export var step := 5.0
@export var color_gradient: GradientTexture1D
@export var analyze_now := false:
	set(value):
		analyze_now = false
		analyze()

var visual_line: Line2D = null

func _enter_tree():
	if not visual_line:
		visual_line = Line2D.new()
		add_child(visual_line)
		visual_line.width = 10
		visual_line.z_index = 999

func analyze():
	clear_children()

	var curve_owner := get_node_or_null(curve_path)
	if not curve_owner or not curve_owner is Path2D:
		push_error("Invalid or missing Path2D.")
		return

	var curve: Curve2D = curve_owner.curve
	var length := curve.get_baked_length()
	var segments := int(length / step)

	var current_cliff: Array = []

	for i in range(segments):
		var p1 = curve.sample_baked(i * step)
		var p2 = curve.sample_baked(min(length, (i + 1) * step))
		var seg = (p2 - p1).normalized()
		var up = (p1 - center).normalized()
		var tangent = Vector2(-up.y, up.x)
		var angle = rad_to_deg(seg.angle_to(tangent))
		var abs_angle = abs(angle)

		var is_steep = abs_angle > max_climb_angle

		if is_steep:
			current_cliff.append({ "p1": p1, "p2": p2 })
		elif current_cliff.size() > 0:
			_draw_cliff_group(current_cliff)
			current_cliff.clear()

	# Finish last group
	if current_cliff.size() > 0:
		_draw_cliff_group(current_cliff)

	print("PathAnalyzer: steep zones labeled.")
	print("PathAnalyzer: analyzed", segments, "segments.")

func _draw_cliff_group(cliff: Array) -> void:
	if cliff.size() == 0:
		return

	var mid_index = int(cliff.size() / 2)
	var mid_point = (cliff[mid_index]["p1"] + cliff[mid_index]["p2"]) / 2.0

	for pair in cliff:
		var line = Line2D.new()
		line.width = 10
		line.default_color = Color.RED
		line.points = PackedVector2Array([pair["p1"], pair["p2"]])
		add_child(line)

	# Label
	var label = Label.new()
	label.text = str(cliff.size()) + "x steep"
	label.scale = Vector2.ONE * 0.5
	add_child(label)
	label.position = mid_point
	
func clear_children():
	for c in get_children():
		c.queue_free()
