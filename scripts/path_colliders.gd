@tool
extends StaticBody2D
class_name PathColliders

@export var path_node_path: NodePath = "../GeneratedPath"
@export var step := 10.0
@export var thickness := 8.0  # total height

@export var generate_now := false:
	set(value):
		generate_now = false
		generate_collider()

@export var clear_now := false:
	set(value):
		clear_now = false
		clear_collider()

var collider_polygon: CollisionPolygon2D

func _ready():
	generate_collider()

func generate_collider():
	print("==> Generating single polygon collider")
	clear_collider()

	var path_node := get_node_or_null(path_node_path)
	if not path_node or not path_node is Path2D:
		push_error("Invalid path_node_path or not a Path2D.")
		return

	var curve: Curve2D = path_node.curve
	if not curve or curve.get_point_count() < 2:
		push_warning("Not enough curve points.")
		return

	var top_points: PackedVector2Array = []
	var bottom_points: PackedVector2Array = []

	var length := curve.get_baked_length()
	var t := 0.0

	while t <= length:
		var pos := curve.sample_baked(t)
		var dir := curve.sample_baked(t + 1.0) - pos
		var normal := Vector2(-dir.y, dir.x).normalized()
		top_points.append(pos + normal * (thickness / 2.0))
		bottom_points.insert(0, pos - normal * (thickness / 2.0)) # reverse order for correct winding
		t += step

	# Close the loop
	var points := top_points
	points.append_array(bottom_points)
	points.append(points[0])  # close polygon

	collider_polygon = CollisionPolygon2D.new()
	collider_polygon.polygon = points
	add_child(collider_polygon)

	print("==> Done: added polygon collider with", points.size(), "points.")

func clear_collider():
	if collider_polygon and collider_polygon.is_inside_tree():
		collider_polygon.queue_free()
	collider_polygon = null
