extends Node2D
class_name Cullable

@export var hydration_distance := 2000.0  # Range to become active

var is_hydrated := true
var target_node: Node = null

func _ready() -> void:
	target_node = get_parent()
	if target_node:
		target_node.add_to_group("Cullable")
	else:
		push_error("Cullable node has no parent to control.")
func set_hydrated(state: bool) -> void:
	if is_hydrated == state or not target_node:
		return
	#print(target_node, "sethydrated", state)
	is_hydrated = state

	# Apply visibility and processing recursively to parent and its children
	target_node.visible = state
	_set_processing_recursive(target_node, state)
	#for child in target_node.get_children():
		#if child is Node:
			#child.visible = state
			#child.set_process(state)
			#child.set_physics_process(state)
func _set_processing_recursive(node: Node, enabled: bool) -> void:
	node.set_process(enabled)
	node.set_physics_process(enabled)
	node.set_process_input(enabled)
	node.set_process_unhandled_input(enabled)
	node.set_process_unhandled_key_input(enabled)

	for child in node.get_children():
		if child is Node:
			_set_processing_recursive(child, enabled)
