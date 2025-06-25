# Atmosphere.gd
extends Control

@export var planet_position: Vector2
@export var sun_position: Vector2

func _process(_delta):
	global_position = get_viewport().get_camera_2d().global_position
	var sun_dir = (sun_position - planet_position).normalized()
	#$TextureRect.material.set_shader_parameter("sun_direction", sun_dir)
