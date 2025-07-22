extends Node
class_name Util

static var dropped_item_scene := preload("res://scenes/items/item_drop.tscn")
static var _frame_token := {}
static var gov_eye: GovernmentEye
var hud: HUDMain = null
var current_collar:CollarMain= null
static func drop_node_as_wrapped_item(node: Node2D, allow_drop := true, _dropped_radius := 3.0) -> void:
	if not allow_drop:
		print("drop_node_as_wrapped_item: not allowed")
		return
	if not node or not node.is_inside_tree():
		print("drop_node_as_wrapped_item: node is invalid or not in tree")
		return
	if not dropped_item_scene:
		push_error("drop_node_as_wrapped_item: dropped_item_scene is null")
		return

	var scene_root := node.get_tree().current_scene
	if not scene_root:
		push_error("drop_node_as_wrapped_item: current scene not found")
		return

	var global_pos := node.global_position
	var global_rot := node.global_rotation
	var global_scale := node.global_scale
	
	var parent = node.get_parent()
	if parent:
		parent.remove_child(node)

	var wrapper := dropped_item_scene.instantiate()
	wrapper.name = "Dropped_%s" % node.name
	wrapper.global_position = global_pos
	wrapper.global_rotation = global_rot

	node.position = Vector2.ZERO
	node.rotation = 0
	node.scale = global_scale
	wrapper.add_child(node)

	scene_root.add_child.call_deferred(wrapper)

static func try_once_per_frame(key: String) -> bool:
	var current_frame = Engine.get_frames_drawn()
	if _frame_token.get(key, -1) == current_frame:
		return false
	_frame_token[key] = current_frame
	return true

func get_current_camera() -> Camera2D:
	var viewport := get_tree().root.get_viewport()
	if viewport:
		var cam := viewport.get_camera_2d()
		if cam and cam.is_inside_tree():
			return cam
	return null

static func get_node_parent_of_type(start: Node, base_class: String) -> Node:
	if not start:
		push_warning("get_node_parent_of_type_base: start is null (looking for %s)" % base_class)
		return null

	var current: Node = start.get_parent()
	while current:
		#print("Checking parent:", current.name, "| base class:", current.get_class())
		if current.get_class() == base_class:
			return current
		current = current.get_parent()

	push_warning("get_node_parent_of_type_base: No parent of base type %s found from %s" % [base_class, start.name])
	return null


static func get_node_child_of_type(start: Node, base_class: String) -> Node:
	if not start:
		push_warning("get_node_child_of_type_base: start is null (looking for %s)" % base_class)
		return null

	print("Checking node:", start.name, "| base class:", start.get_class())
	if start.get_class() == base_class:
		return start

	for child in start.get_children():
		var found := get_node_child_of_type(child, base_class)
		if found:
			return found

	push_warning("get_node_child_of_type_base: No child of base type %s found under %s" % [base_class, start.name])
	return null
	
static func generate_guid() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return "%08x-%04x-%04x-%04x-%012x" % [
		rng.randi(),
		rng.randi() & 0xFFFF,
		rng.randi() & 0xFFFF,
		rng.randi() & 0xFFFF,
		rng.randi()
	]
func get_active_collar():
	return current_collar
	
