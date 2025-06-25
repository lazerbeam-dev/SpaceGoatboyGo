@tool
extends Node2D
class_name PathFillRenderer

@export var path_node_path: NodePath = "../GeneratedPath"
@export var fill_texture: Texture2D
@export var fill_material: Material
@export var step := 5.0
@export var uv_scale := Vector2(1.0, 1.0)

@export var draw_now := false:
	set(value):
		draw_now = false
		update_fill()

@export var clear_now := false:
	set(value):
		clear_now = false
		clear_fill()

var polygon_node: Polygon2D = null

func _enter_tree():
	ensure_polygon_node()

func _ready():
	if Engine.is_editor_hint():
		update_fill()
	else:
		call_deferred("update_fill")

func ensure_polygon_node():
	if not polygon_node or not is_instance_valid(polygon_node):
		polygon_node = Polygon2D.new()
		add_child(polygon_node)
		polygon_node.name = "PathFill"
		polygon_node.z_index = -3
		polygon_node.antialiased = false
		polygon_node.texture = fill_texture
		polygon_node.material = fill_material
		polygon_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func update_fill():
	ensure_polygon_node()

	var path_node := get_node_or_null(path_node_path)
	if not path_node:
		push_error("Missing path node.")
		return

	var baked := PackedVector2Array()

	if path_node is Path2D:
		var curve: Curve2D = path_node.curve
		if not curve:
			push_warning("Missing curve in Path2D.")
			return
		baked = curve.get_baked_points()
	elif path_node is Line2D:
		baked = path_node.points.duplicate()
	else:
		push_error("Node must be Path2D or Line2D.")
		return

	if baked.size() < 3:
		polygon_node.polygon = PackedVector2Array()
		polygon_node.visible = false
		return

	if baked[0].distance_to(baked[-1]) > step:
		baked.append(baked[0])

	var uvs := PackedVector2Array()
	for point in baked:
		uvs.append(point * uv_scale)

	polygon_node.polygon = baked
	polygon_node.uv = uvs
	polygon_node.texture = fill_texture
	polygon_node.material = fill_material
	polygon_node.visible = true
	queue_redraw()

func clear_fill():
	ensure_polygon_node()
	polygon_node.polygon = PackedVector2Array()
	polygon_node.visible = false
	queue_redraw()
