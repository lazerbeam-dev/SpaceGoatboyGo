extends Node2D
class_name CreatureArms

@export var root_path: NodePath = "../../"
@export var health_path: NodePath

var arms: Array = []
var arm_weapon_map := {}
var weapon_groups := {}
var facing_right: bool = true
var manual_aim_target: Vector2 = Vector2.ZERO
var use_manual_aim: bool = false

const AIM_THRESHOLD = 0.1
const ARM_LERP_SPEED = 800.0

@onready var creature: Creature = get_node_or_null(root_path)

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
	arms = find_arms_recursive(self)
	print(self, " found...", arms.count, "arms")

	for arm in arms:
		var we = arm.find_weapon_recursive(arm)
		if we is Weapon:
			equip_existing_weapon(we, arm)

	if has_node(health_path):
		var health_node = get_node(health_path)
		if health_node.has_signal("died"):
			health_node.connect("died", Callable(self, "_on_owner_died"))
		else:
			push_warning("Health node at %s has no 'died' signal." % health_path)
	else:
		push_warning("Health node not found at path: %s" % health_path)

func _on_owner_died():
	print("Owner died. Disabling arms.")
	for arm in arms:
		arm.set_process(false)
		arm.set_physics_process(false)
		arm.process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta):
	var aim_target_world_pos = get_aim_target_world_position()
	if aim_target_world_pos == Vector2.ZERO:
		return

	point_arms(aim_target_world_pos, delta)

	var current_time = Time.get_ticks_msec() / 1000.0

	for raw_cd in weapon_groups:
		var cd = snapped(raw_cd, 0.001)
		var group: Array = weapon_groups[raw_cd].filter(func(f): return is_instance_valid(f.weapon))
		weapon_groups[raw_cd] = group

		if group.is_empty():
			continue

		group.sort_custom(func(a, b): return a.next_fire_time < b.next_fire_time)

		for fire_data in group:
			var arm = arm_weapon_map.find_key(fire_data.weapon)
			if not arm:
				continue

			var to_target = aim_target_world_pos - arm.global_position
			var target_angle = to_target.angle()
			var angle_diff = abs(angle_difference(arm.global_rotation, target_angle))

			fire_data.is_aimed = angle_diff < AIM_THRESHOLD

			if fire_data.is_aimed and current_time >= fire_data.next_fire_time:
				var fire_dir = Vector2.RIGHT.rotated(fire_data.weapon.global_rotation)
				fire_data.weapon.attempt_fire(fire_dir, current_time)
				fire_data.next_fire_time = current_time + cd

func point_arms(target: Vector2, delta: float):
	for arm in arms:
		var to_target = (target - arm.global_position).normalized()
		arm.target_direction = to_target
		arm.is_mirrored = not facing_right

func get_aim_target_world_position() -> Vector2:
	return manual_aim_target if use_manual_aim else Vector2.ZERO

func equip_existing_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon
	print(self, " equipped ", weapon.name)

	var raw_cd = weapon.cooldown
	var cd = snapped(raw_cd, 0.001)

	if not weapon_groups.has(cd):
		weapon_groups[cd] = []

	var group = weapon_groups[cd]

	# Prevent duplicates
	for fire_data in group:
		if fire_data.weapon == weapon:
			print("Weapon already equipped:", weapon.name, "— skipping duplicate")
			return

	group.append(WeaponFireData.new(weapon, 0.0))  # temp offset
	# Calculate and assign effective_z_index
	var total_z := weapon.z_index
	var node := weapon.get_parent()
	while node:
		if node is CanvasItem:
			total_z += node.z_index
		node = node.get_parent()
	weapon.effective_z_index = total_z
	# Now recalculate all offsets in one clean pass
	var n = group.size()
	for i in range(n):
		group[i].offset = float(i) / n * cd
		group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[i].offset

	print("Weapon group for cooldown:", cd)
	for f in group:
		print(creature, "-", f.weapon.name, "offset:", f.offset, "next_fire_time:", f.next_fire_time)

func equip_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon

	# Position correctly
	if arm.has_method("get_hand_pos_gun_z"):
		var gnz = arm.get_hand_pos_gun_z()
		weapon.global_position = gnz.hp
		weapon.z_index = gnz.gz
	else:
		weapon.global_position = arm.global_position
	weapon.rotation = 0

	# Calculate and assign effective_z_index
	var total_z := weapon.z_index
	var node := weapon.get_parent()
	while node:
		if node is CanvasItem:
			total_z += node.z_index
		node = node.get_parent()
	weapon.effective_z_index = total_z

	# Group logic with proper offset calculation
	var cd = weapon.cooldown
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


func drop_weapon(weapon: Weapon):
	if not is_instance_valid(weapon):
		return

	weapon.drop_self()
	var arm = arm_weapon_map.find_key(weapon)
	if arm:
		arm_weapon_map.erase(arm)

	var groups_to_clean := []
	for raw_cd in weapon_groups:
		var cd = snapped(raw_cd, 0.001)
		var group = weapon_groups[raw_cd]
		var new_group := []

		for f in group:
			if f.weapon != weapon:
				new_group.append(f)

		if new_group.is_empty():
			groups_to_clean.append(raw_cd)
		else:
			for i in range(new_group.size()):
				new_group[i].offset = (float(i) / new_group.size()) * cd
				new_group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + new_group[i].offset
			weapon_groups[raw_cd] = new_group

	for cd in groups_to_clean:
		weapon_groups.erase(cd)

func drop_weapons():
	for weapon in arm_weapon_map.values():
		drop_weapon(weapon)

func find_arms_recursive(root: Node) -> Array:
	var found := []
	if root is Arm:
		found.append(root)
	for c in root.get_children():
		found += find_arms_recursive(c)
	return found
