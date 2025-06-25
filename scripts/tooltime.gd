@tool
extends Node2D

@export var shader_path: String = "res://shaders/emotional_material.gdshader"
@export var apply_now: bool = false : set = _on_apply_now_changed

var shared_material: ShaderMaterial = null

func _on_apply_now_changed(value):
	apply_now = false
	if not Engine.is_editor_hint():
		return

	var shader = load(shader_path)
	if shader == null:
		push_error("Could not load shader at %s" % shader_path)
		return

	if shared_material == null:
		shared_material = ShaderMaterial.new()
		shared_material.shader = shader

	var root = get_tree().edited_scene_root
	if root == null:
		push_error("No edited_scene_root found.")
		return

	print("Applying emotional material to all Sprite2Ds under: %s" % root.name)
	var count := _apply_to_all_sprite2ds(root)
	print("Applied to %d Sprite2Ds." % count)

func _apply_to_all_sprite2ds(node: Node) -> int:
	var applied := 0
	if node is Sprite2D:
		node.material = shared_material
		applied += 1
		print(" -> Applied to: %s" % node.name)
	for child in node.get_children():
		applied += _apply_to_all_sprite2ds(child)
	return applied
