class_name Utils

static func get_scene_root(node: Node) -> Node:
	var current = node
	while current.get_parent() and current.get_parent().owner == node.owner:
		current = current.get_parent()
	return current
