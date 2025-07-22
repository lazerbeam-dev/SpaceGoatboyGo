@tool
extends Node2D
class_name CliffTransitionAnalyzer

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
var cliff_midpoints: Array[Vector2] = []

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
	var length: float = curve.get_baked_length()
	var segments: int = int(length / step)
	var current_cliff: Array = []
	var was_cliff: bool = false
	var lookback_distance: float = step * 3
	var lookahead_distance: float = step * 3

	for i in range(segments):
		var p1: Vector2 = curve.sample_baked(i * step)
		var p2: Vector2 = curve.sample_baked(min(length, (i + 1) * step))
		var seg: Vector2 = (p2 - p1).normalized()
		var up: Vector2 = (p1 - center).normalized()
		var tangent: Vector2 = Vector2(-up.y, up.x)
		var angle: float = rad_to_deg(seg.angle_to(tangent))
		var abs_angle: float = abs(angle)
		var is_steep: bool = abs_angle > max_climb_angle

		if i > 0:
			if was_cliff and not is_steep:
				var cliff_start_pos: Vector2 = curve.sample_baked(max(0, i * step - lookback_distance))
				var normal_end_pos: Vector2 = curve.sample_baked(min(length, i * step + lookahead_distance))
				var cliff_direction: Vector2 = (p1 - cliff_start_pos).normalized()
				var normal_direction: Vector2 = (normal_end_pos - p1).normalized()
				var turn_angle: float = rad_to_deg(cliff_direction.angle_to(normal_direction))
				create_transition_marker(p1, turn_angle, "Cliff→Normal", cliff_direction, normal_direction)
			elif not was_cliff and is_steep:
				var normal_start_pos: Vector2 = curve.sample_baked(max(0, i * step - lookback_distance))
				var cliff_end_pos: Vector2 = curve.sample_baked(min(length, i * step + lookahead_distance))
				var normal_direction: Vector2 = (p1 - normal_start_pos).normalized()
				var cliff_direction: Vector2 = (cliff_end_pos - p1).normalized()
				var turn_angle: float = rad_to_deg(normal_direction.angle_to(cliff_direction))
				create_transition_marker(p1, turn_angle, "Normal→Cliff", normal_direction, cliff_direction)

		if is_steep:
			current_cliff.append({ "p1": p1, "p2": p2 })
		elif current_cliff.size() > 0:
			draw_cliff_group(current_cliff)
			current_cliff.clear()

		was_cliff = is_steep

	if current_cliff.size() > 0:
		draw_cliff_group(current_cliff)

	print("CliffTransitionAnalyzer: steep zones and transitions labeled.")
	print("CliffTransitionAnalyzer: analyzed", segments, "segments.")

func create_transition_marker(pos: Vector2, turn_angle: float, transition_type: String, incoming_dir: Vector2, outgoing_dir: Vector2):
	var left_turn: bool = turn_angle < 0.0

	var in_start: Vector2 = pos - incoming_dir * 50
	var out_end: Vector2 = pos + outgoing_dir * 50

	var in_line: Line2D = Line2D.new()
	in_line.width = 4
	in_line.default_color = Color.GREEN
	in_line.points = PackedVector2Array([in_start, pos])
	add_child(in_line)

	var out_line: Line2D = Line2D.new()
	out_line.width = 4
	out_line.default_color = Color.BLUE
	out_line.points = PackedVector2Array([pos, out_end])
	add_child(out_line)

	var label: Label = Label.new()
	label.text = transition_type + " Turn: " + str(round(turn_angle * 10) / 10) + "°"
	label.scale = Vector2.ONE * 0.6
	label.position = pos + Vector2(15, -25)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.z_index = 1000
	add_child(label)

	var in_tag: Label = Label.new()
	in_tag.text = "GL" if left_turn else "GR"
	in_tag.scale = Vector2.ONE * 0.5
	in_tag.position = in_start - incoming_dir * 5
	in_tag.z_index = 1000
	add_child(in_tag)

	var out_tag: Label = Label.new()
	out_tag.text = "BL" if left_turn else "BR"
	out_tag.scale = Vector2.ONE * 0.5
	out_tag.position = out_end + outgoing_dir * 5
	out_tag.z_index = 1000
	add_child(out_tag)

	# Find nearest cliff
	if cliff_midpoints.is_empty():
		return

	var closest_cliff: Vector2 = cliff_midpoints[0]
	var min_dist: float = pos.distance_to(closest_cliff)
	for c: Vector2 in cliff_midpoints:
		var d: float = pos.distance_to(c)
		if d < min_dist:
			min_dist = d
			closest_cliff = c

	# Decide marker direction
	var in_proj: Vector2 = in_start.lerp(pos, 0.5)
	var out_proj: Vector2 = pos.lerp(out_end, 0.5)
	var use_outgoing: bool = out_proj.distance_to(closest_cliff) < in_proj.distance_to(closest_cliff)
	var final_pos: Vector2 = out_proj if use_outgoing else in_proj

	# Marker (black square)
	var marker: ColorRect = ColorRect.new()
	marker.color = Color.BLACK
	marker.size = Vector2(10, 10)
	marker.position = final_pos - marker.size / 2
	marker.z_index = 1001
	add_child(marker)

	print("Transition at ", pos, ": ", transition_type, " with turn angle: ", turn_angle, "°")

func draw_cliff_group(cliff: Array) -> void:
	if cliff.is_empty():
		return

	var mid_index: int = int(cliff.size() / 2.0)
	var mid_point: Vector2 = (cliff[mid_index]["p1"] + cliff[mid_index]["p2"]) / 2.0
	cliff_midpoints.append(mid_point)

	for pair in cliff:
		var line: Line2D = Line2D.new()
		line.width = 10
		line.default_color = Color.RED
		line.points = PackedVector2Array([pair["p1"], pair["p2"]])
		add_child(line)

	var label: Label = Label.new()
	label.text = str(cliff.size()) + "x steep"
	label.scale = Vector2.ONE * 0.5
	label.position = mid_point
	add_child(label)

func clear_children():
	cliff_midpoints.clear()
	for c in get_children():
		c.queue_free()
