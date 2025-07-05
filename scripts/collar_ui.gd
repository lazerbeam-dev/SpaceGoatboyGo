extends Node2D
class_name CollarUIManager
func update_goatboy_status(data: Dictionary) -> void:
	print("yo")
	if not data.has("health"):
		return
	var health_ratio: float = clamp(data["health"], 0.0, 1.0)
	if Utils.hud:
		Utils.hud.update_hp_ratio(health_ratio)
