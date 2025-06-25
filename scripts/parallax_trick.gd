@tool
extends Node2D
class_name AngularScrollingBackground

@export var camera_path: NodePath
@export var center := Vector2.ZERO
@export var texture: Texture2D
@export var parallax_factor := 0.5
@export var screen_height := 360.0
@export var loops_per_rotation := 1.0  # how many times the texture loops per full orbit

var camera: Camera2D

func _ready():
	camera = get_node_or_null(camera_path)

func _process(_delta):
	queue_redraw()

func _draw():
	if not texture or not is_instance_valid(camera):
		return

	var cam_angle = (camera.global_position - center).angle()
	var scroll_x = cam_angle / TAU * texture.get_width() * loops_per_rotation * parallax_factor
	scroll_x = fposmod(scroll_x, texture.get_width())

	var repeat_count = ceil(get_viewport_rect().size.x / texture.get_width()) + 2

	for i in range(repeat_count):
		var offset_x = -scroll_x + i * texture.get_width()
		draw_texture(texture, Vector2(offset_x, -screen_height / 2.0))
