@tool
extends StaticBody2D
class_name PathColliders

@export var path_node_path: NodePath = "../GeneratedPath"
@export var step := 10.0
@export var thickness := 8.0  # total height of the rectangle

@export var generate_now := false:
	set(value):
		generate_now = false
		generate_colliders()

@export var clear_now := false:
	set(value):
		clear_now = false
		clear_colliders()

func _ready():
	generate_colliders()

func generate_colliders():
	print("==> Generating thick path colliders")
	clear_colliders()

	var path_node := get_node_or_null(path_node_path)
	if not path_node or not path_node is Path2D:
		push_error("Invalid path_node_path or not a Path2D.")
		return

	var curve: Curve2D = path_node.curve
	if not curve or curve.get_point_count() < 2:
		push_warning("Not enough curve points to generate colliders.")
		return

	var length := curve.get_baked_length()
	var t := 0.0

	while t < length - step:
		var p1 := curve.sample_baked(t)
		var p2 := curve.sample_baked(t + step)
		_create_thick_segment(p1, p2)
		t += step

	# Final loop segment
	var p_last := curve.sample_baked(length - step)
	var p_first := curve.sample_baked(0.0)
	_create_thick_segment(p_last, p_first)

	print("==> Done: added", get_child_count(), "thick segments.")

func _create_thick_segment(p1: Vector2, p2: Vector2) -> void:
	var dir = p2 - p1
	var len = dir.length()
	if len == 0.0:
		return

	var angle = dir.angle()
	var mid = (p1 + p2) / 2.0

	var rect = RectangleShape2D.new()
	rect.extents = Vector2(len / 2.0, thickness / 2.0)

	var shape_node = CollisionShape2D.new()
	shape_node.shape = rect
	shape_node.position = mid
	shape_node.rotation = angle

	add_child(shape_node)

func clear_colliders():
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	print("==> Cleared all thick segment colliders.")
