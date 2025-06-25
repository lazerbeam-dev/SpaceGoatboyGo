@tool
extends Node2D
class_name AngularParallaxer

@export var target_path: NodePath
@export var camera_path: NodePath
@export var center_position: Vector2 = Vector2.ZERO
@export var parallax_strength := -2.0  # Your preferred default

@export var update_now := false:
	set(value):
		update_now = false
		if Engine.is_editor_hint():
			_update_parallax()

var _target: Node2D
var _camera: Node2D
var _last_vector := Vector2.RIGHT

func _ready():
	_target = get_node_or_null(target_path)
	_camera = get_node_or_null(camera_path)
	if not _target or not _camera:
		push_error("Missing target or camera.")
		return
	_last_vector = _get_camera_vector()

func _process(delta):
	if not _target or not _camera:
		return

	var current_vector := _get_camera_vector()
	var delta_angle := _last_vector.angle_to(current_vector)
	_target.rotation -= delta_angle * parallax_strength
	_last_vector = current_vector

func _get_camera_vector() -> Vector2:
	return (_camera.global_position - center_position).normalized()

func _update_parallax():
	if not _target or not _camera:
		return
	var current_vector := _get_camera_vector()
	var angle := Vector2.RIGHT.angle_to(current_vector)
	_target.rotation = -angle * parallax_strength
	_last_vector = current_vector
