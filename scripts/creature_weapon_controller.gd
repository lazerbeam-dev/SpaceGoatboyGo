extends Node2D
class_name CreatureWeaponController

@export var camera_path: NodePath
@export var camera: Camera2D
@export var health_node_path: NodePath

var arm_weapon_map := {}
var weapon_groups := {}
var facing_right := true
var arms := []
var click_world_target_position := Vector2.ZERO
var is_mouse_down := false
var health_node: Node = null

class WeaponFireData:
	var weapon: Weapon
	var next_fire_time: float
	var offset: float
	var is_aimed: bool = false

	func _init(w: Weapon, offset_val: float):
		weapon = w
		offset = offset_val
		next_fire_time = Time.get_ticks_msec() / 1000.0 + offset_val

func _ready():
	arm_weapon_map.clear()
	weapon_groups.clear()
	arms.clear()

	arms = find_arms_recursive(self)

	await get_tree().process_frame

	if has_node(health_node_path):
		health_node = get_node(health_node_path)
		health_node.connect("died", Callable(self, "_on_death_signal"))
		print("Connected to died signal.")
	else:
		push_warning("Health node not found at path: %s" % health_node_path)

func pilot_input(pilot_data: Dictionary) -> void:
	if pilot_data.has("aim_world_position"):
		click_world_target_position = pilot_data["aim_world_position"]

	if pilot_data.has("fire"):
		is_mouse_down = pilot_data["fire"]

	if pilot_data.has("facing_right"):
		facing_right = pilot_data["facing_right"]

func get_aim_target_world_position() -> Vector2:
	return click_world_target_position

func _process(_delta: float) -> void:
	if camera == null:
		camera = Utils.get_current_camera()

	var aim_target_world_pos = get_aim_target_world_position()
	point_arms(aim_target_world_pos)

	if aim_target_world_pos == Vector2.ZERO:
		is_mouse_down = false
		return

	var current_time = Time.get_ticks_msec() / 1000.0

	for cooldown in weapon_groups:
		var group = weapon_groups[cooldown]
		group = group.filter(func(fire_data): return is_instance_valid(fire_data.weapon))
		weapon_groups[cooldown] = group

		for fire_data in group:
			var weapon_arm = arm_weapon_map.find_key(fire_data.weapon)
			if weapon_arm:
				var current_arm_aim_dir = (aim_target_world_pos - weapon_arm.global_position).normalized()
				var current_arm_global_angle = weapon_arm.global_rotation
				var target_arm_global_angle = current_arm_aim_dir.angle()

				var angle_diff = abs(angle_difference(current_arm_global_angle, target_arm_global_angle))
				fire_data.is_aimed = angle_diff < 0.15

			if current_time >= fire_data.next_fire_time and fire_data.is_aimed and is_mouse_down:
				var fire_aim_dir = Vector2.RIGHT.rotated(fire_data.weapon.global_rotation)
				fire_data.weapon.attempt_fire(fire_aim_dir, current_time)
				fire_data.next_fire_time = current_time + cooldown

func switch_weapon_for_arm(arm: Arm, new_weapon):
	if arm_weapon_map.has(arm):
		var old_weapon = arm_weapon_map[arm]
		drop_weapon(old_weapon)

	if new_weapon is PackedScene:
		new_weapon = new_weapon.instantiate()
		new_weapon.name = "Weapon"
		arm.add_child(new_weapon)
	else:
		new_weapon.name = "Weapon"

	equip_weapon(new_weapon, arm)

func equip_weapon(weapon: Weapon, arm: Arm) -> void:
	arm_weapon_map[arm] = weapon

	# Remove from old parent before reparenting
	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)

	var hand_node := arm.get_node_or_null("HandPos")
	if hand_node:
		hand_node.add_child(weapon)
		weapon.position = Vector2.ZERO
		weapon.rotation = 0.0
	else:
		push_warning("No HandPos found on arm: %s" % arm.name)

	var cd := weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []

	var group = weapon_groups[cd]
	var weapon_index_in_group = group.size()
	var offset = 0.0

	if weapon_index_in_group > 0:
		offset = (float(weapon_index_in_group) / (weapon_index_in_group + 1)) * cd
		for i in range(group.size()):
			group[i].offset = (float(i) / (weapon_index_in_group + 1)) * cd
			group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[i].offset

	var fire_data = WeaponFireData.new(weapon, offset)
	group.append(fire_data)


func point_arms(aim_target_world_pos: Vector2):
	for arm in arms:
		if aim_target_world_pos == Vector2.ZERO:
			arm.target_direction = Vector2.ZERO
		else:
			var dir_to_target = (aim_target_world_pos - arm.global_position).normalized()
			arm.target_direction = dir_to_target
		arm.is_mirrored = not facing_right

func find_arms_recursive(root: Node) -> Array:
	var found := []
	if root is Arm:
		found.append(root)
	for child in root.get_children():
		found += find_arms_recursive(child)
	return found

func drop_weapon(weapon: Weapon):
	if not is_instance_valid(weapon):
		return

	weapon.drop_self(true)
	var arm = arm_weapon_map.find_key(weapon)
	if arm:
		arm_weapon_map.erase(arm)

	var groups_to_clean := []
	for cooldown in weapon_groups:
		var group = weapon_groups[cooldown]
		var new_group := []

		for fire_data in group:
			if fire_data.weapon != weapon:
				new_group.append(fire_data)

		if new_group.is_empty():
			groups_to_clean.append(cooldown)
		else:
			for i in range(new_group.size()):
				new_group[i].offset = (float(i) / new_group.size()) * cooldown
				new_group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + new_group[i].offset
			weapon_groups[cooldown] = new_group

	for cooldown in groups_to_clean:
		weapon_groups.erase(cooldown)

func drop_weapons():
	for weapon in arm_weapon_map.values():
		drop_weapon(weapon)

func _on_death_signal():
	drop_weapons()
	set_process(false)
	set_physics_process(false)
