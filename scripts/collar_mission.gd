extends Node
class_name CollarMission

signal mission_completed
signal mission_failed(reason: String)
signal mission_updated

@export var mission: Mission
@export var government_tolerance: float = 1.0

var is_active := false
var current_kills := 0
var target_kills := 0

func start_mission():
	if not mission:
		push_error("CollarMission: No mission assigned.")
		return

	current_kills = 0
	target_kills = 0

	for goal in mission.goals:
		if goal.has_method("get_target_kills"):
			target_kills += goal.get_target_kills()

	is_active = true
	emit_signal("mission_updated")
	Utils.mission_control.receive_mission(mission)

func update(delta: float, goat_position: Vector2):
	if not is_active or mission == null:
		return

	if mission.bounds and mission.bounds.is_inside(goat_position):
		government_tolerance -= mission.tolerance_decay_rate * delta
	else:
		government_tolerance += mission.tolerance_restore_rate * delta

	government_tolerance = clamp(government_tolerance, 0.0, 1.0)

	#for fail in mission.fail_conditions:
		#if fail.is_failed():
			#emit_signal("mission_failed", fail.get_reason())
			#is_active = false
			#return
#
	#if government_tolerance <= mission.hard_fail_threshold:
		#print("MISSION FAILED")
		#emit_signal("mission_failed", "government_tolerance")
		#is_active = false
		#return

	_check_completion()

func register_kill(tag: String):
	if not is_active or mission == null:
		return

	var updated := false

	for goal in mission.goals:
		if goal is KillCountGoal:
			var g := goal as KillCountGoal
			var before := g.get_progress()
			g.register_kill(tag)
			if g.get_progress() > before:
				current_kills += 1
				updated = true

	if updated:
		emit_signal("mission_updated")
		_check_completion()

func _check_completion():
	if not is_active:
		return

	for goal in mission.goals:
		if not goal.is_complete():
			return

	is_active = false
	emit_signal("mission_completed")
	print("MISSION COMPLETE")

	if Utils.gov_particles:
		Utils.gov_particles.play_effect("mission_complete")

	# Show "MISSION COMPLETE!" in HUD
	if Utils.hud:
		Utils.hud.show_mission("MISSION COMPLETE!")

	await get_tree().create_timer(5.0).timeout
	_generate_new_kill_mission()


func get_status_data() -> Dictionary:
	return {
		"description": mission.description,
		"progress": str(current_kills) + " / " + str(target_kills),
		"tolerance": government_tolerance
	}

func get_status_text() -> String:
	return "%s\nProgress: %d / %d\nTolerance: %.0f%%" % [
		mission.description,
		current_kills, target_kills,
		government_tolerance * 100.0
	]
func _generate_new_kill_mission():
	var kill_goal_count := randi_range(1, 10)

	# Create the kill goal
	var kill_goal := KillCountGoal.new()
	kill_goal.target_tag = "shroom"
	kill_goal.required_kills = kill_goal_count

	# Use goatboy's current position as mission center
	var center :Vector2= Utils.get_active_collar().global_position
	var bounds := CircularMissionBounds.new()
	bounds.center = center
	bounds.radius = 2000.0

	var new_mission := Mission.new()
	new_mission.description = "Eliminate %d mushrooms in the area." % kill_goal_count
	new_mission.goals = [kill_goal]
	new_mission.fail_conditions = []
	new_mission.bounds = bounds

	mission = new_mission
	start_mission()
