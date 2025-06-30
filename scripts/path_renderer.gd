@tool
extends Node2D
class_name PathRenderer

@export var path_node_path: NodePath = "../GeneratedPath"
@export var colliders_node_path: NodePath = "../PathColliders"
@export var texture: Texture2D
@export var line_width := 32.0
@export var step := 10.0
@export var vertical_offset := 0.0
@export var cliff_texture: Texture2D
@export var max_climb_angle := 45.0
@export var cliff_line_width := 32.0
@export var center := Vector2.ZERO
@export var cliff_backtrack := 1  # Number of previous steps to prepend to start of cliff

@export var line_material: Material  # Shared material for all Line2Ds

@export var draw_now := false:
	set(value):
		draw_now = false
		update_render()

@export var clear_now := false:
	set(value):
		clear_now = false
		clear_render()

var debug_path_points: PackedVector2Array = []
var flat_segments: Array = []
var cliff_segments: Array = []

func _ready():
	if Engine.is_editor_hint():
		update_render()
	else:
		call_deferred("update_render")

func update_render() -> void:
	var path_node: Path2D = get_node_or_null(path_node_path)
	if not path_node or not path_node is Path2D:
		push_error("Invalid or missing path_node (Path2D)")
		return

	var curve: Curve2D = path_node.curve
	if not curve:
		push_warning("Missing curve on path_node")
		return

	clear_render()

	var baked_length: float = curve.get_baked_length()
	var segments: int = int(baked_length / step)

	var current_segment: Array[Vector2] = []
	var prev_points: Array[Vector2] = []
	var prev_type: bool = false  # true = steep, false = flat
	var first_type_set: bool = false

	for i in range(segments):
		var p1: Vector2 = curve.sample_baked(i * step)
		var p2: Vector2 = curve.sample_baked(min(baked_length, (i + 1) * step))
		var seg: Vector2 = (p2 - p1).normalized()
		var up: Vector2 = (p1 - center).normalized()
		var tangent: Vector2 = Vector2(-up.y, up.x)
		var angle: float = rad_to_deg(seg.angle_to(tangent))
		var abs_angle: float = abs(angle)
		var is_steep: bool = abs_angle > max_climb_angle

		var switching := first_type_set and is_steep != prev_type

		if switching:
			if prev_type:
				var extended = current_segment.duplicate()
				var last_point = extended.back()
				var prev_seg = (last_point - extended[extended.size() - 2]).normalized()
				extended[-1] = last_point + prev_seg * step * 0.1
				cliff_segments.append(extended)
			else:
				flat_segments.append(current_segment.duplicate())
			current_segment.clear()

		if current_segment.is_empty():
			# Prepend prior flat points if we're entering a cliff
			if is_steep and cliff_backtrack > 0 and prev_points.size() >= cliff_backtrack:
				for j in range(cliff_backtrack):
					current_segment.append(prev_points[-cliff_backtrack + j])
			current_segment.append(p1)

		current_segment.append(p2)

		# Track previous points for optional backtrack use
		if not is_steep:
			if prev_points.size() >= cliff_backtrack:
				prev_points.pop_front()
			prev_points.append(p1)

		prev_type = is_steep
		first_type_set = true

	if current_segment.size() > 1:
		var final = current_segment.duplicate()
		if prev_type:
			var last_point = final.back()
			var prev_seg = (last_point - final[final.size() - 2]).normalized()
			final[-1] = last_point + prev_seg * step * 0.1
			cliff_segments.append(final)
		else:
			flat_segments.append(final)

	_render_flat_segments()
	_render_cliffs()

func _render_flat_segments():
	for segment in flat_segments:
		var line := Line2D.new()
		add_child(line)
		line.z_index = -2
		line.texture = texture
		line.material = line_material
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.width = line_width
		line.points = PackedVector2Array(segment)

func _render_cliffs():
	for segment in cliff_segments:
		var line := Line2D.new()
		add_child(line)
		line.z_index = -2
		line.texture = cliff_texture
		line.material = line_material
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.width = cliff_line_width
		line.points = PackedVector2Array(segment)

func clear_render():
	flat_segments.clear()
	cliff_segments.clear()
	debug_path_points.clear()

	for child in get_children():
		if child is Line2D:
			remove_child(child)
			child.queue_free()

	queue_redraw()
