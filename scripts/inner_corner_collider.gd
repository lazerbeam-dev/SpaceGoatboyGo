@tool
extends Node2D
class_name InnerCornerCapper

@export var curve_path: NodePath = "../GeneratedPath"
@export var max_climb_angle := 45.0
@export var center := Vector2.ZERO
@export var step := 5.0
@export var cap_length := 12.0
@export var analyze_now := false:
	set(value):
		analyze_now = false
		analyze()
		
@export var clear_now := false:
	set(value):
		clear_now = false
		clear_caps()

func analyze():
	clear_caps()

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
			current_cliff.append({ "p1": p1, "p2": p2, "seg": seg })
		elif current_cliff.size() > 0:
			_place_caps(current_cliff)
			current_cliff.clear()

	if current_cliff.size() > 0:
		_place_caps(current_cliff)

func _place_caps(cliff: Array) -> void:
	if cliff.size() == 0:
		return

	var first = cliff.front()
	var last = cliff.back()

	# Tangent direction (floor)
	var seg_first = first["seg"]
	var seg_last = last["seg"]

	# Normal direction (inward = "wall")
	var normal_first = Vector2(-seg_first.y, seg_first.x)
	var normal_last = Vector2(-seg_last.y, seg_last.x)

	# Floor caps (aligned with terrain)
	_create_segment_collider(first["p1"], first["p1"] + seg_first * cap_length)
	_create_segment_collider(last["p2"], last["p2"] - seg_last * cap_length)

	# Wall caps (pointing inward)
	_create_segment_collider(first["p1"], first["p1"] + normal_first * cap_length)
	_create_segment_collider(last["p2"], last["p2"] + normal_last * cap_length)

func _create_segment_collider(p1: Vector2, p2: Vector2) -> void:
	var static_body = StaticBody2D.new()
	var collider = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	shape.a = Vector2.ZERO
	shape.b = p2 - p1
	collider.shape = shape
	static_body.position = p1
	static_body.add_child(collider)
	add_child(static_body)

func clear_caps():
	for c in get_children():
		c.queue_free()
