extends Node2D
class_name CreatureArms

@export var root_path: NodePath = "../../"
@export var health_path: NodePath = "../../Health"

var arms: Array = []
var arm_weapon_map := {}
var weapon_groups := {}
var facing_right: bool = true
var manual_aim_target: Vector2 = Vector2.ZERO
var use_manual_aim: bool = false

const AIM_THRESHOLD = 0.15

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

	for arm in arms:
		var weapon = arm.find_weapon_recursive(arm)
		if weapon is Weapon:
			equip_existing_weapon(weapon, arm)

	if has_node(health_path):
		var health_node = get_node(health_path)
		if health_node.has_signal("died"):
			health_node.connect("died", Callable(self, "_on_owner_died"))
		else:
			push_warning("Health node at %s has no 'died' signal." % health_path)
	else:
		push_warning("Health node not found at path: %s" % health_path)

func _on_owner_died():
	drop_weapons()
	for arm in arms:
		arm.set_process(false)
		arm.set_physics_process(false)
		arm.process_mode = Node.PROCESS_MODE_DISABLED
	self.set_process(false)
	self.set_physics_process(false)

func _process(_delta):
	var aim_target = get_aim_target_world_position()
	if aim_target == Vector2.ZERO:
		return

	point_arms(aim_target)

	var current_time = Time.get_ticks_msec() / 1000.0

	for cooldown in weapon_groups:
		var group = weapon_groups[cooldown]
		group = group.filter(func(f): return is_instance_valid(f.weapon))
		weapon_groups[cooldown] = group

		for fire_data in group:
			var arm = arm_weapon_map.find_key(fire_data.weapon)
			if not arm:
				continue

			var to_target = (aim_target - arm.global_position).normalized()
			var angle_diff = abs(angle_difference(arm.global_rotation, to_target.angle()))
			fire_data.is_aimed = angle_diff < AIM_THRESHOLD

			if current_time >= fire_data.next_fire_time and fire_data.is_aimed:
				var fire_dir = Vector2.RIGHT.rotated(fire_data.weapon.global_rotation)
				fire_data.weapon.attempt_fire(fire_dir, current_time)
				fire_data.next_fire_time = current_time + cooldown

func point_arms(target: Vector2):
	for arm in arms:
		arm.target_direction = (target - arm.global_position).normalized()
		arm.is_mirrored = not facing_right

func get_aim_target_world_position() -> Vector2:
	return manual_aim_target if use_manual_aim else Vector2.ZERO

func equip_existing_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon
	var cd = weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []
	var group = weapon_groups[cd]

	# Prevent duplicates
	for f in group:
		if f.weapon == weapon:
			return

	# Compute offset based on group size
	var offset = 0.0
	if group.size() > 0:
		offset = (float(group.size()) / (group.size() + 1)) * cd
		for i in range(group.size()):
			group[i].offset = (float(i) / (group.size() + 1)) * cd
			group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[i].offset

	var fire_data = WeaponFireData.new(weapon, offset)
	group.append(fire_data)

func drop_weapon(weapon: Weapon):
	if not is_instance_valid(weapon):
		return

	weapon.drop_self(false)

	var arm = arm_weapon_map.find_key(weapon)
	if arm:
		arm_weapon_map.erase(arm)

	var to_clean := []
	for cd in weapon_groups:
		var group = weapon_groups[cd].filter(func(f): return f.weapon != weapon)
		if group.is_empty():
			to_clean.append(cd)
		else:
			for i in range(group.size()):
				group[i].offset = float(i) / group.size() * cd
				group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[i].offset
			weapon_groups[cd] = group

	for cd in to_clean:
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
