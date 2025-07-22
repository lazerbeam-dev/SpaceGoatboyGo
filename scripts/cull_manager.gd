extends Node2D
class_name CullController

@export var hydration_distance := 2000.0
@export var check_interval := 0.25

var camera: Camera2D
var _timer := 0.0
var _cullables := []

func _ready():
	camera = Utils.get_current_camera()
	_cullables = get_tree().get_nodes_in_group("Cullable")

func _process(delta):
	_timer += delta
	if _timer < check_interval:
		return
	_timer = 0.0

	if not camera:
		return

	var cam_pos = camera.global_position

	for target in _cullables:
		if not is_instance_valid(target):
			continue

		var cull_tag :Node2D= target.get_node_or_null("CullTag")  # <- Assumes Cullable is named this
		if cull_tag == null:
			continue

		var dist :float= target.global_position.distance_to(cam_pos)
		cull_tag.set_hydrated(dist <= hydration_distance)
