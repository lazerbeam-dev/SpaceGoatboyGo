@tool
extends Node2D
class_name ForegroundMushroomPlacer

@export var path_node: NodePath
@export var mushroom_scenes: Array[PackedScene] = []
@export var _myseed: int = 42
@export var density: float = 1.0  # Mushrooms per 100 pixels
@export var clear_existing := false
@export var generate_now := false:
	set(value):
		if value:
			generate_now = false
			generate()

var rng := RandomNumberGenerator.new()

func generate():
	if not is_instance_valid(get_node_or_null(path_node)):
		push_error("Path node invalid.")
		return

	if mushroom_scenes.is_empty():
		push_error("No mushroom scenes assigned.")
		return

	var path: Path2D = get_node(path_node)
	var curve := path.curve
	if not curve or curve.get_point_count() < 2:
		push_error("Path must have a valid Curve2D with at least 2 points.")
		return

	if clear_existing:
		for child in get_children():
			child.queue_free()

	rng.seed = _myseed

	var points: PackedVector2Array = curve.get_baked_points()
	var total_length = curve.get_baked_length()

	var count = int(density * total_length / 100.0)
	print("==> Total baked path length: %.2f" % total_length)
	print("==> Mushroom count target: %d" % count)

	for i in range(count):
		var t = rng.randf_range(0.0, total_length)
		var pos = curve.sample_baked(t)

		# Approximate tangent using forward difference
		var delta := 1.0
		var t2 : float= clamp(t + delta, 0.0, total_length)
		var pos2 := curve.sample_baked(t2)
		var tangent := (pos2 - pos).normalized()
		#var normal := tangent.orthogonal().normalized()

		var mushroom = mushroom_scenes[rng.randi_range(0, mushroom_scenes.size() - 1)].instantiate()
		add_child(mushroom)
		mushroom.global_position = pos
		mushroom.rotation = tangent.angle()  # optional

		var center = get_path_center(points)
		var depth = 0
		if pos.y > center.y:
			depth = rng.randi_range(1, 3)
		elif pos.y < center.y:
			depth = -1
		mushroom.z_index = depth

		print("Mushroom #%d:" % i)
		print("  t @ %.2f px" % t)
		print("  Position: %s" % pos)
		print("  Tangent angle: %.2f°" % rad_to_deg(tangent.angle()))
		print("  Z-Index: %d" % depth)

func get_path_center(points: PackedVector2Array) -> Vector2:
	var sum = Vector2.ZERO
	for p in points:
		sum += p
	return sum / points.size()
