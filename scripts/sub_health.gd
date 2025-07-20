extends CollisionShape2D
class_name SubHealthShape

@export var main_health_path: NodePath  # Optional: Path to the main DestructibleShape
var main_health_node: Node = null

@export var debug_passthrough := false  # Optional debug toggle

func _ready():
	if main_health_path.is_empty():
		# Try to auto-find a sibling DestructibleShape
		for sibling in get_parent().get_children():
			if sibling != self and sibling is DestructibleShape:
				main_health_node = sibling
				break
		if not main_health_node:
			push_warning("SubHealthShape: No DestructibleShape sibling found.")
	else:
		main_health_node = get_node_or_null(main_health_path)
		if not main_health_node:
			push_warning("SubHealthShape: Could not find node at path: %s" % main_health_path)

func receive_impact(payload: Dictionary, source: Node = null) -> void:
	if not main_health_node:
		push_warning("SubHealthShape: No main health node to forward to.")
		return
	main_health_node.call("receive_impact", payload, source)
