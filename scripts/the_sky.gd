extends Node2D
class_name TheSky

@export var emotional_material: ShaderMaterial
@export var emotional_material_creature: ShaderMaterial

@export var day_color := Color(0.6, 0.8, 1.0)
@export var night_color := Color(0.05, 0.05, 0.1)

@export var center_of_planet := Vector2.ZERO
@export var the_sun_path: NodePath
@export var camera_path: NodePath
@export var color_rect_path: NodePath

@export_range(0.0, 1.0) var creature_blend_amount := 0.2
@export_range(0.0, 1.0) var object_blend_amount := 0.5

var the_sun: Node2D
var camera: Camera2D
var color_rect: ColorRect
var current_color := Color.WHITE

func _ready():
	the_sun = get_node_or_null(the_sun_path)
	camera = get_node_or_null(camera_path)
	color_rect = get_node_or_null(color_rect_path)

	if not the_sun or not camera:
		push_error("TheSky: Missing required node(s).")

func _process(_delta):
	if not emotional_material or not is_instance_valid(camera) or not is_instance_valid(the_sun):
		return

	var sun_dir = (the_sun.global_position - center_of_planet).normalized()
	var cam_dir = (camera.global_position - center_of_planet).normalized()
	var day_ratio = clamp(sun_dir.dot(cam_dir), -1.0, 1.0) * 0.5 + 0.5  # 0 = midnight, 1 = noon

	# Compute base sky color and alpha fade at night
	current_color = day_color.lerp(night_color, 1.0 - day_ratio)
	var sky_alpha: float = clamp(day_ratio * 1.5, 0.0, 1.0)

	# Apply to world shaders
	emotional_material.set_shader_parameter("blend_color", current_color)
	emotional_material.set_shader_parameter("blend_amount", object_blend_amount)

	if emotional_material_creature:
		emotional_material_creature.set_shader_parameter("blend_color", current_color)
		emotional_material_creature.set_shader_parameter("blend_amount", creature_blend_amount)

	if color_rect:
		color_rect.color = Color(current_color.r, current_color.g, current_color.b, sky_alpha)
