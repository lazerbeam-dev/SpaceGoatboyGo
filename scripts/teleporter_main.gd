extends Node
class_name TeleporterMain

@export var goatboy_scene: PackedScene
@export var goatboys_required := 1
@export var spawn_point: NodePath
@export var control_antenna: NodePath
@export var check_interval := 1.0

var goatboys_alive := 0
var spawn_node: Node2D
var antenna: GoatboyControlAntenna = null
var last_spawned_goatboy: Node = null
var last_spawned_goatboy_collar: Node = null
var connected := false

func _ready():
	spawn_node = get_node_or_null(spawn_point)
	if not spawn_node:
		push_error("Spawn point not found.")
		return

	antenna = get_node_or_null(control_antenna) as GoatboyControlAntenna
	if not antenna:
		push_error("Control antenna not found.")
		return

	if not connected:
		antenna.connect("goatboy_died", Callable(self, "_on_antenna_goatboy_died"))
		antenna.connect("goatboy_control_acquired", Callable(self, "_on_goatboy_control_acquired"))
		connected = true

	_spawn_timer()

func _spawn_timer():
	while true:
		await get_tree().create_timer(check_interval).timeout
		_check_and_spawn()

func _check_and_spawn():
	if goatboys_alive < goatboys_required:
		await _spawn_goatboy()

func _spawn_goatboy() -> void:
	if not goatboy_scene:
		push_error("No goatboy_scene assigned.")
		return

	var goatboy = goatboy_scene.instantiate()
	goatboy.add_to_group("goatboy")
	goatboy.global_position = spawn_node.global_position
	get_tree().current_scene.add_child(goatboy)
	goatboys_alive += 1
	last_spawned_goatboy = goatboy
	#last_spawned_goatboy_collar
	var cam_controller = get_tree().root.get_node_or_null("Game/CameraController")
	if cam_controller and cam_controller is Node2D:
		pass
	else:
		push_warning("CameraController not found under Game.")

	await get_tree().create_timer(0.25).timeout

	antenna.target = goatboy
	antenna.send_ping({
		"type": "ping",
		"i_am_control_tower": true,
		"from": self.name,
		"from_node": self,
		"time": Time.get_unix_time_from_system(),
		"mission": create_dummy_mission()
	})

	if GameControl.player == null:
		GameControl.set_player(goatboy)

func _on_goatboy_control_acquired(payload: Dictionary) -> void:
	var source := payload.get("source") as Node2D
	last_spawned_goatboy_collar = source
	#print("TeleporterMain: Goatboy control acquired:", payload)

func _on_antenna_goatboy_died(payload: Dictionary) -> void:
	var source := payload.get("source") as Node2D
	if source != last_spawned_goatboy and source != last_spawned_goatboy_collar:
		#print("TeleporterMain: Ignored goatboy_died from stale source")
		return

	#print("TeleporterMain: Got goatboy death report:", payload)
	goatboys_alive = max(0, goatboys_alive - 1)

func create_dummy_mission():
	# === MISSION CREATION ===
	var mission := Mission.new()
	mission.description = "Eliminate mushrooms in the designated zone."

	# Kill Goal
	var kill_goal := KillCountGoal.new()
	kill_goal.required_kills = 1
	kill_goal.target_tag = "shroom"

	# Bounds
	var bounds := CircularMissionBounds.new()
	bounds.center = spawn_node.global_position
	bounds.radius = 2000.0

	mission.goals = [kill_goal]
	mission.fail_conditions = []  # Could add timeout or friendly fire later
	mission.bounds = bounds
	return mission
