@tool
extends Node2D
class_name SquarePathwright

@export var size := 1000.0
@export var auto_generate := false:
	set(value):
		auto_generate = value
		if Engine.is_editor_hint() and value:
			print("Auto-generate triggered from editor")
			generate_path()

@export var clear_path_button := false:
	set(value):
		clear_path_button = false
		clear_path()

@onready var path_node: Path2D = $GeneratedSquare

func generate_path():
	print("==> Generating square path")
	clear_path()

	var half := size / 2.0
	var points := [
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
		Vector2(-half, -half),  # close the loop
	]

	var curve := Curve2D.new()
	for p in points:
		curve.add_point(p)

	path_node.curve = curve
	print("Square curve assigned to path_node")

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update...")
		renderer.update_render()
	else:
		print("No renderer found or update_render method missing")

func clear_path():
	print("==> Clearing path")
	if path_node and path_node.curve:
		path_node.curve.clear_points()
		print("Path curve cleared")
	else:
		print("WARNING: path_node or its curve is null")

	var renderer := get_node_or_null("PathRenderer")
	if renderer and "update_render" in renderer:
		print("Triggering renderer update after clear")
		renderer.update_render()
	else:
		print("No renderer to update after clear")
