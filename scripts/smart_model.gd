extends Node2D
class_name SmartModel

@export var dissolve_material: ShaderMaterial = preload("res://assets/shaders/dissolve.tres")
@export var default_noise_texture: Texture2D = preload("res://assets/sprites/misc/MMFlowNoise.png")
@export var dissolve_speed := 2

@export var excluded_sprites_paths: Array[NodePath] = [] # List of nodes to ignore when applying dissolve

var sprite_map: Dictionary = {}
var is_dissolved := false
var dissolve_coroutine_running := false
var excluded_sprites: Array[Node2D] = []

func _ready():
	dissolve_speed = 2
	excluded_sprites.clear()
	for path in excluded_sprites_paths:
		var node = get_node_or_null(path)
		if node and node is Node2D:
			excluded_sprites.append(node)
	cache_all_sprites(self)

func cache_all_sprites(root: Node) -> void:
	for child in root.get_children():
		cache_all_sprites(child)

	if root is Sprite2D:
		if excluded_sprites.has(root):
			pass
		elif root.owner != self.owner:
			pass
		else:
			sprite_map[root] = {
				"material": root.material,
				"z_index": root.z_index,
			}


func apply_dissolve(blend_color: Color, blend_amount: float, dissolve_amount: float = 0.0, edge_color: Color = Color(1,1,1)):
	if not dissolve_material:
		push_error("No dissolve material assigned.")
		return

	for sprite in sprite_map.keys():
		if not is_instance_valid(sprite):
			continue
		var mat := dissolve_material.duplicate() as ShaderMaterial
		mat.set_shader_parameter("blend_color", blend_color)
		mat.set_shader_parameter("blend_amount", blend_amount)
		mat.set_shader_parameter("dissolve_amount", dissolve_amount)
		mat.set_shader_parameter("edge_color", edge_color)

		if default_noise_texture:
			mat.set_shader_parameter("noise_texture", default_noise_texture)

		sprite.material = mat

	is_dissolved = true

func revert_materials():
	for sprite in sprite_map.keys():
		if not is_instance_valid(sprite):
			continue
		var data = sprite_map[sprite]
		sprite.material = data.material
		sprite.z_index = data.z_index
	is_dissolved = false

func begin_dissolve(payload: Dictionary = {}):
	if dissolve_coroutine_running:
		return
	dissolve_coroutine_running = true
	_start_dissolve(payload)

func _start_dissolve(payload: Dictionary) -> void:
	var blend_color := Color(1, 1, 1)
	var blend_amount := 0.0

	for mat_data in sprite_map.values():
		if mat_data.material is ShaderMaterial:
			blend_color = mat_data.material.get_shader_parameter("blend_color")
			blend_amount = mat_data.material.get_shader_parameter("blend_amount")
			break
	if self.owner.name == "GoatboyCollar":
		print("dissolving COLLAR")
	var edge_color := Color(1, 1, 1)
	if payload.has("colour"):
		var named_color = payload["colour"]
		if named_color is String:
			match named_color.to_lower():
				"red": edge_color = Color(1, 0, 0)
				"green": edge_color = Color(0, 1, 0)
				"blue": edge_color = Color(0, 0.4, 1)
				"yellow": edge_color = Color(1, 1, 0)
				"purple": edge_color = Color(0.7, 0, 1)
				_: push_warning("Unknown dissolve colour: %s" % named_color)
		else:
			push_warning("Dissolve payload 'colour' was not a string: %s" % typeof(named_color))
	else:
		push_warning("No 'colour' key found in dissolve payload.")

	var dissolve_amount := 0.01
	apply_dissolve(blend_color, blend_amount, dissolve_amount, edge_color)
	await _dissolve_over_time(blend_color, blend_amount)
	dissolve_coroutine_running = false

func _dissolve_over_time(_blend_color: Color, _blend_amount: float) -> void:
	var dissolve := 0.01
	while dissolve < 1.0:
		dissolve += dissolve_speed * get_process_delta_time()
		dissolve = min(dissolve, 1.0)
		for sprite in sprite_map.keys():
			if not is_instance_valid(sprite):
				continue
			var mat := sprite.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("dissolve_amount", dissolve)
		await get_tree().process_frame

func remove_sprite_for_node(sprite: Node2D):
	if sprite_map.has(sprite):
		sprite_map.erase(sprite)

func shift_z_index(offset: int):
	z_index += offset
