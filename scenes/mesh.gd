@tool
extends Node2D
class_name SpriteShapeMeshBuilder

@export var path_node_path: NodePath = "../GeneratedPath"
@export var texture: Texture2D
@export var fill_height := 100.0
@export var step := 16.0
@export var vertical_offset := 0.0
@export var close_mode := "flat" # options: "flat", "mirror"

var mesh_instance: MeshInstance2D
var collider: CollisionPolygon2D

func _ready():
	generate_mesh()

func generate_mesh():
	print("==> Generating closed sprite shape mesh")

	if mesh_instance and mesh_instance.is_inside_tree():
		mesh_instance.queue_free()
	if collider and collider.is_inside_tree():
		collider.queue_free()

	var path_node := get_node_or_null(path_node_path)
	if not path_node or not path_node is Path2D:
		push_error("Invalid path node")
		return

	var curve : Curve2D= path_node.curve
	if not curve or curve.get_point_count() < 2:
		push_warning("Curve too small")
		return

	var top_points := PackedVector2Array()
	var bottom_points := PackedVector2Array()
	var length := curve.get_baked_length()
	var t := 0.0

	# Collect top points
	while t <= length:
		var pt := curve.sample_baked(t) + Vector2(0, vertical_offset)
		top_points.append(pt)
		t += step

	# Build bottom points
	match close_mode:
		"mirror":
			for i in range(top_points.size() - 1, -1, -1):
				var pt = top_points[i]
				bottom_points.append(pt + Vector2(0, fill_height))
		"flat":
			var left = top_points[0]
			var right = top_points[top_points.size() - 1]
			bottom_points.append(right + Vector2(0, fill_height))
			bottom_points.append(left + Vector2(0, fill_height))
		_:
			push_warning("Invalid close_mode")
			return

	var all_points := top_points.duplicate()
	all_points.append_array(bottom_points)

	# Build mesh
	mesh_instance = MeshInstance2D.new()
	add_child(mesh_instance)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match close_mode:
		"mirror":
			for i in range(top_points.size() - 1):
				var p1 = top_points[i]
				var p2 = top_points[i + 1]
				var p3 = bottom_points[bottom_points.size() - 2 - i]
				var p4 = bottom_points[bottom_points.size() - 1 - i]

				var u1 = float(i) / float(top_points.size())
				var u2 = float(i + 1) / float(top_points.size())

				st.set_uv(Vector2(u1, 0))
				st.add_vertex(Vector3(p1.x, p1.y, 0))
				st.set_uv(Vector2(u1, 1))
				st.add_vertex(Vector3(p3.x, p3.y, 0))
				st.set_uv(Vector2(u2, 0))
				st.add_vertex(Vector3(p2.x, p2.y, 0))

				st.set_uv(Vector2(u2, 0))
				st.add_vertex(Vector3(p2.x, p2.y, 0))
				st.set_uv(Vector2(u1, 1))
				st.add_vertex(Vector3(p3.x, p3.y, 0))
				st.set_uv(Vector2(u2, 1))
				st.add_vertex(Vector3(p4.x, p4.y, 0))
		"flat":
		# Single quad across top and flat base
			for i in range(top_points.size() - 1):
				var p1 = top_points[i]
				var p2 = top_points[i + 1]
				var p3 = bottom_points[1]
				var p4 = bottom_points[0]

				var u1 = float(i) / float(top_points.size())
				var u2 = float(i + 1) / float(top_points.size())

				st.set_uv(Vector2(u1, 0))
				st.add_vertex(Vector3(p1.x, p1.y, 0))
				st.set_uv(Vector2(u1, 1))
				st.add_vertex(Vector3(p3.x, p3.y, 0))
				st.set_uv(Vector2(u2, 0))
				st.add_vertex(Vector3(p2.x, p2.y, 0))

				st.set_uv(Vector2(u2, 0))
				st.add_vertex(Vector3(p2.x, p2.y, 0))
				st.set_uv(Vector2(u1, 1))
				st.add_vertex(Vector3(p3.x, p3.y, 0))
				st.set_uv(Vector2(u2, 1))
				st.add_vertex(Vector3(p4.x, p4.y, 0))
	var mesh = st.commit()
	mesh_instance.mesh = mesh

	if texture:
		var mat := ShaderMaterial.new()
		mat.shader = Shader.new()
		mat.shader.code = """
shader_type canvas_item;
uniform sampler2D texture_albedo : source_color;
void fragment() {
	COLOR = texture(texture_albedo, UV);
}
"""
		mat.set_shader_parameter("texture_albedo", texture)
		mesh_instance.material = mat

	# Build collider
	var static_body = StaticBody2D.new()
	add_child(static_body)

	collider = CollisionPolygon2D.new()
	collider.polygon = all_points
	static_body.add_child(collider)

	print("==> Mesh and collision complete")
