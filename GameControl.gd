extends Node
class_name GameControl

static var player: Node = null

static func set_player(new_player: Node) -> void:
	if new_player == null:
		push_warning("Attempted to assign null as player.")
		return
	player = new_player
	print("[GameControl] Player assigned:", player)
