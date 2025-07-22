extends Node
class_name CollarWeaponPilot

@export var weapon_controller: CreatureWeaponController = null
@export var camera: Camera2D
@export var facing_right_reference: Creature  # must have `facing_right: bool`

var available_weapons: Array[PackedScene] = [
	preload("res://scenes/weapons/shotgun.tscn"),
	preload("res://scenes/weapons/smg.tscn"),
	preload("res://scenes/weapons/grenade_launcher.tscn"),
	preload("res://scenes/weapons/rifle.tscn"),
	preload("res://scenes/weapons/pistol.tscn"),
	preload("res://scenes/weapons/minigun.tscn"),
]

var weapon_index := 0
var fire_requested := false
var click_aim_position := Vector2.ZERO
var using_mouse_aim := false

func _process(_delta):
	if not weapon_controller or not camera or not facing_right_reference:
		return

	var pilot_data := {}

	if using_mouse_aim and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		click_aim_position = camera.get_global_mouse_position()
		pilot_data["aim_world_position"] = click_aim_position
		pilot_data["fire"] = true
	else:
		using_mouse_aim = false
		var x := int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		var y := int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		var aim_dir := Vector2(x, y).normalized()
		
		if aim_dir != Vector2.ZERO:
			var world_dir := aim_dir.rotated(camera.global_rotation)
			print("fcr: ", facing_right_reference.global_position, "worlddir: ", world_dir, " aim_dir: ", aim_dir)
			pilot_data["aim_world_position"] = facing_right_reference.global_position + world_dir * 500.0
			pilot_data["fire"] = true
		else:
			var local_down := Vector2.DOWN.rotated(facing_right_reference.global_rotation)
			pilot_data["aim_world_position"] = facing_right_reference.global_position + local_down * 300.0
			pilot_data["fire"] = false

	pilot_data["facing_right"] = facing_right_reference.facing_right
	weapon_controller.pilot_input(pilot_data)

	if Input.is_action_just_pressed("switch_weapon"):
		weapon_index = (weapon_index + 1) % available_weapons.size()
		var new_weapon_scene = available_weapons[weapon_index]
		for arm in weapon_controller.arms:
			weapon_controller.switch_weapon_for_arm(arm, new_weapon_scene)
		_update_weapon_icons()

func _update_weapon_icons():
	var icons: Array[Texture] = []
	for arm in weapon_controller.arms:
		var weapon = weapon_controller.arm_weapon_map.get(arm, null)
		if weapon and weapon.has_node("Sprite2D"):
			var sprite: Sprite2D = weapon.get_node("Sprite2D")
			icons.append(sprite.texture)
		else:
			icons.append(null)

	var ui_manager: Node = get_parent().get_node_or_null("CollarUIManager")
	if ui_manager and ui_manager.has_method("update_weapon_icons_for_arms"):
		ui_manager.update_weapon_icons_for_arms(icons)

func handle_input_fire_request(event: InputEvent) -> void:
	if not (weapon_controller and camera and facing_right_reference):
		print("Refused fire input: controller, camera, or reference missing.")
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				using_mouse_aim = true
				click_aim_position = camera.get_global_mouse_position()
			else:
				using_mouse_aim = false
