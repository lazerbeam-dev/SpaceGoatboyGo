extends Node
class_name TeleporterMain

@export var goatboy_scene: PackedScene
@export var goatboys_required := 1
@export var spawn_point: NodePath  # Assign a Marker2D or Position2D
@export var check_interval := 1.0  # seconds
@export var control_antenna : NodePath
var goatboys_alive := 0
var spawn_node: Node2D

func _ready():
	spawn_node = get_node_or_null(spawn_point)
	if not spawn_node:
		push_error("Spawn point not found.")
		return

	# Start regular check
	_spawn_timer()

func _spawn_timer():
	while true:
		await get_tree().create_timer(check_interval).timeout
		_check_and_spawn()

func _check_and_spawn():
	if goatboys_alive < goatboys_required:
		_spawn_goatboy()

func _spawn_goatboy():
	if not goatboy_scene:
		push_error("No goatboy_scene assigned.")
		return

	var goatboy = goatboy_scene.instantiate()
	goatboy.global_position = spawn_node.global_position
	get_tree().current_scene.add_child(goatboy)
	goatboys_alive += 1

	# Set camera follow target
	var cam_controller = get_tree().root.get_node_or_null("Game/CameraController")
	if cam_controller and cam_controller is Node2D:
		cam_controller.target = goatboy
		var cs = goatboy.get_node("Model/ControlSystem")
		cs.init_goatboy(cam_controller, goatboy)
	else:
		push_warning("CameraController not found under Game.")
	var antenna = get_node_or_null(control_antenna) as GoatboyControlAntenna
	if antenna:
		antenna.target = goatboy
	# Set GameControl player
	if GameControl.player == null:
		GameControl.set_player(goatboy)

func _on_goatboy_died():
	goatboys_alive = max(0, goatboys_alive - 1)
