@tool
extends Node2D
class_name PathRenderer

@export var path_node_path: NodePath = "../GeneratedPath"
@export var colliders_node_path: NodePath = "../PathColliders"
@export var texture: Texture2D
@export var line_width := 32.0
@export var step := 10.0
@export var vertical_offset := 0.0

@export var left_cap_texture: Texture2D
@export var right_cap_texture: Texture2D

var debug_path_points: PackedVector2Array = []

@export var draw_now := false:
	set(value):
		draw_now = false
		update_render()

@export var clear_now := false:
	set(value):
		clear_now = false
		clear_render()

var line2d: Line2D = null
var left_cap_sprite: Sprite2D = null
var right_cap_sprite: Sprite2D = null

func _enter_tree():
	ensure_line_node()
	ensure_cap_sprites()

func _ready():
	if Engine.is_editor_hint():
		update_render()  # In editor
	else:
		call_deferred("update_render")  # At runtime

func ensure_line_node():
	if not line2d or not is_instance_valid(line2d):
		line2d = Line2D.new()
		add_child(line2d)
	line2d.z_index = -2
	line2d.width = line_width
	line2d.texture = texture
	line2d.texture_mode = Line2D.LINE_TEXTURE_TILE

func ensure_cap_sprites():
	if not left_cap_sprite or not is_instance_valid(left_cap_sprite):
		left_cap_sprite = Sprite2D.new()
		left_cap_sprite.name = "LeftCap"
		add_child(left_cap_sprite)

	if not right_cap_sprite or not is_instance_valid(right_cap_sprite):
		right_cap_sprite = Sprite2D.new()
		right_cap_sprite.name = "RightCap"
		add_child(right_cap_sprite)

func update_render():
	var path_node: Path2D = get_node_or_null(path_node_path)
	var colliders_node: Node = get_node_or_null(colliders_node_path)
	if not path_node or not path_node is Path2D:
		push_error("Invalid or missing path_node (Path2D)")
		return
	if not colliders_node:
		push_error("Invalid or missing colliders_node")
		return

	ensure_line_node()
	ensure_cap_sprites()
	line2d.clear_points()
	debug_path_points.clear()

	var center: Vector2 = global_position
	var edge_points: Array = []

	for collider in colliders_node.get_children():
		if collider is CollisionShape2D and collider.shape is RectangleShape2D:
			var rect: RectangleShape2D = collider.shape
			var transform: Transform2D = collider.get_global_transform()
			var extents: Vector2 = rect.extents

			# Top left and top right corners in local space
			var p1_local: Vector2 = Vector2(-extents.x, -extents.y)
			var p2_local: Vector2 = Vector2(extents.x, -extents.y)

			# Convert to global
			var p1: Vector2 = transform * p1_local
			var p2: Vector2 = transform * p2_local

			# Pick the one furthest from the planet center
			var chosen: Vector2
			if p1.distance_to(center) > p2.distance_to(center):
				chosen = p1
			else:
				chosen = p2
			edge_points.append(chosen)
	if edge_points.size() > 1:
		edge_points.append(edge_points[0])  # Close loop
	debug_path_points = PackedVector2Array(edge_points)
	#debug_path_points = PackedVector2Array(edge_points)
	line2d.points = debug_path_points
	queue_redraw()

func _draw():
	pass
	#if debug_path_points.size() > 1:
		#draw_polyline(debug_path_points, Color.BLUE, 2.0)

func clear_render():
	if line2d and is_instance_valid(line2d):
		line2d.clear_points()
	debug_path_points.clear()
	queue_redraw()
