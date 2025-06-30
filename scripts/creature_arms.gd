extends Node2D
class_name CreatureArms

@export var root_path: NodePath = "../../"  # Path to the Creature root
@export var health_path: NodePath          # Path to the health node to monitor for "died"

var arms: Array = []
var arm_weapon_map := {}
var weapon_groups := {}
var facing_right: bool = true
var manual_aim_target: Vector2 = Vector2.ZERO
var use_manual_aim: bool = false

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

	# Connect to health's "died" signal if available
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
	point_arms(aim_target_world_pos)
	facing_right = creature.facing_right

	if aim_target_world_pos == Vector2.ZERO:
		return

	var current_time = Time.get_ticks_msec() / 1000.0

	for cooldown in weapon_groups:
		var group = weapon_groups[cooldown].filter(func(f): return is_instance_valid(f.weapon))
		weapon_groups[cooldown] = group

		for fire_data in group:
			var arm = arm_weapon_map.find_key(fire_data.weapon)
			if arm:
				var dir = (aim_target_world_pos - arm.global_position).normalized()
				fire_data.is_aimed = abs(angle_difference(arm.global_rotation, dir.angle())) < 0.15

			if fire_data.is_aimed and current_time >= fire_data.next_fire_time:
				var fire_dir = Vector2.RIGHT.rotated(fire_data.weapon.global_rotation)
				fire_data.weapon.attempt_fire(fire_dir, current_time)
				fire_data.next_fire_time = current_time + cooldown

func get_aim_target_world_position() -> Vector2:
	return manual_aim_target if use_manual_aim else Vector2.ZERO

func point_arms(target: Vector2):
	for arm in arms:
		arm.target_direction = (target - arm.global_position).normalized() if target != Vector2.ZERO else Vector2.ZERO
		arm.is_mirrored = not facing_right
func equip_existing_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon
	print(self, " equipped ", weapon.name)

	var cd = weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []

	var group = weapon_groups[cd]
	var i = group.size()
	var offset = (float(i) / (i + 1)) * cd if i > 0 else 0.0

	for j in range(group.size()):
		group[j].offset = (float(j) / (i + 1)) * cd
		group[j].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[j].offset

	var fire_data = WeaponFireData.new(weapon, offset)
	group.append(fire_data)

func equip_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon
	print(self, " equipped ", weapon.name)
	if arm.has_method("get_hand_pos_gun_z"):
		var gnz = arm.get_hand_pos_gun_z()
		weapon.global_position = gnz.hp
		weapon.z_index = gnz.gz
	else:
		weapon.global_position = arm.global_position

	weapon.rotation = 0

	var cd = weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []

	var group = weapon_groups[cd]
	var i = group.size()
	var offset = (float(i) / (i + 1)) * cd if i > 0 else 0.0

	for j in range(group.size()):
		group[j].offset = (float(j) / (i + 1)) * cd
		group[j].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[j].offset

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
	for cd in weapon_groups:
		var group = weapon_groups[cd]
		var new_group := []
		for f in group:
			if f.weapon != weapon:
				new_group.append(f)

		if new_group.is_empty():
			groups_to_clean.append(cd)
		else:
			for i in range(new_group.size()):
				new_group[i].offset = (float(i) / new_group.size()) * cd
				new_group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + new_group[i].offset
			weapon_groups[cd] = new_group

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
