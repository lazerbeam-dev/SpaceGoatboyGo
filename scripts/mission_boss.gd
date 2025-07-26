extends Mission
class_name BossMission
signal mission_updated

@export var target_position_nodes: Array[NodePath] = []
var boss: SGEntity
var is_complete := false

func _ready():
	if boss and boss.has_signal("died"):
		boss.died.connect(_on_boss_defeated)
	emit_signal("mission_updated")
func _on_boss_defeated():
	is_complete = true
	emit_signal("mission_updated")
	print("[BossMission] Boss eliminated!")

func get_status_text() -> String:
	if is_complete:
		return "✔ Target eliminated"
	elif is_instance_valid(boss):
		var pos = boss.global_position
		return "Eliminate target at (%.0f, %.0f)" % [pos.x, pos.y]
	else:
		return "Find and eliminate the high priority target."
