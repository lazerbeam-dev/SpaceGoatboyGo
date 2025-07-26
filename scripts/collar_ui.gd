extends Node
class_name CollarUIManager
func update_goatboy_status(data: Dictionary) -> void:
	if not data.has("health"):
		return
	var health_ratio: float = clamp(data["health"], 0.0, 1.0)
	if Utils.hud:
		Utils.hud.update_hp_ratio(health_ratio)
func update_mission_status(mission_data: Dictionary) -> void:
	if not Utils.hud:
		return

	var lines := []

	var description :String= mission_data.get("description", "")
	if description != "":
		lines.append(description)

	var goals :Array= mission_data.get("goals", [])
	for goal in goals:
		if typeof(goal) != TYPE_DICTIONARY:
			continue
		var desc :String= goal.get("description", "")
		var progress :float= goal.get("progress", 0.0)

func update_weapon_icons_for_arms(textures: Array[Texture]) -> void:
	if Utils.hud:
		Utils.hud.update_weapon_icons(textures)
func lgln(msg: String) -> void:
	if Utils.hud:
		Utils.hud.debug_log(msg)
