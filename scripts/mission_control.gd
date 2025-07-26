extends Node
class_name MissionControl

var active_mission: Mission = null
var collar_mission: Node = null
var poll_timer := 0.0
const POLL_INTERVAL := 1.0

func _ready() -> void:
	Utils.mission_control = self

func _process(delta: float) -> void:
	poll_timer += delta
	if poll_timer >= POLL_INTERVAL:
		poll_timer = 0.0
		_poll_for_collar()

func _poll_for_collar():
	var collar = Utils.get_active_collar()
	if not collar:
		return

	var new_collar_mission = collar.get_node_or_null("CollarMission")
	if new_collar_mission != collar_mission:
		if collar_mission and collar_mission.is_connected("mission_updated", _on_mission_updated):
			collar_mission.disconnect("mission_updated", _on_mission_updated)

		collar_mission = new_collar_mission

		if collar_mission and collar_mission.has_signal("mission_updated"):
			collar_mission.mission_updated.connect(_on_mission_updated, CONNECT_DEFERRED)

	_update_hud()

func receive_mission(mission: Mission):
	active_mission = mission
	print("[MissionControl] Received mission:", mission.description)
	_poll_for_collar()

func register_kill(victim_tag: String):
	if collar_mission and collar_mission.has_method("register_kill"):
		collar_mission.register_kill(victim_tag)
func _on_mission_updated():
	_update_hud()

func _update_hud():
	if collar_mission and collar_mission.has_method("get_status_text"):
		Utils.hud.show_mission(collar_mission.get_status_text())
	else:
		Utils.hud.show_mission("")
