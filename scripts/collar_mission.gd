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

	# Initialize progress tracking
	current_kills = 0
	target_kills = 0

	for goal in mission.goals:
		if goal.has_method("get_target_kills"):
			target_kills += goal.get_target_kills()

	is_active = true
	emit_signal("mission_updated")

func update(delta: float, goat_position: Vector2):
	if not is_active or mission == null:
		return

	# Update tolerance
	if not mission.bounds.is_inside(goat_position):
		government_tolerance -= mission.tolerance_decay_rate * delta
	else:
		government_tolerance += mission.tolerance_restore_rate * delta

	government_tolerance = clamp(government_tolerance, 0.0, 1.0)

	# Check fail conditions
	for fail in mission.fail_conditions:
		if fail.is_failed():
			emit_signal("mission_failed", fail.get_reason())
			is_active = false
			return

	if government_tolerance <= mission.hard_fail_threshold:
		print("MISSION FAILED")
		emit_signal("mission_failed", "government_tolerance")
		is_active = false
		return

	# Check goal completion
	var all_complete := true
	for goal in mission.goals:
		if not goal.is_complete():
			all_complete = false
			break

	if all_complete:
		emit_signal("mission_completed")
		is_active = false

func increment_kill_count(amount := 1):
	if not is_active:
		return

	current_kills += amount
	emit_signal("mission_updated")

	if current_kills >= target_kills:
		emit_signal("mission_completed")
		is_active = false

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
