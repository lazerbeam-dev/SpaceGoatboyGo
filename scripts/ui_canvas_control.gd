extends CanvasLayer
class_name UIControlCenter

@export var emoji_nodes: Array[NodePath]  # Point to EmojiHealth, EmojiFuel, etc.
@export var emoji_choices := ["🔥", "💀", "🚀", "⚡", "🧠"]

func _ready():
	for path in emoji_nodes:
		var node = get_node_or_null(path)
		if node and node.has_method("set_text"):
			node.set_text(_random_emoji())

func _random_emoji() -> String:
	return emoji_choices[randi() % emoji_choices.size()]
