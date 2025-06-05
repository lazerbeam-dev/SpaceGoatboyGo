extends Node
class_name CreatureWeaponController

var weapons := []
var weapon_groups := {}
var firing_offsets := {}
var group_timers := {}
var facing_right := true  # Set externally by player
var arms := []  # Cached references to Arm nodes

func _ready():
	print("CreatureWeaponController initialized.")
	
	# Reset
	weapons.clear()
	weapon_groups.clear()
	firing_offsets.clear()
	group_timers.clear()
	arms.clear()

	# Cache arms (any depth under this node)
	arms = find_arms_recursive(self)
	print("Found %d arms." % arms.size())

	# Cache weapons
	var found_weapons = find_weapons_recursive(self)
	print("Found %d weapons." % found_weapons.size())

	for weapon in found_weapons:
		equip_weapon(weapon)

func _process(delta):
	if weapons.is_empty():
		print("No weapons!")
		return  # Early return if empty

	var aim_dir = get_aim_vector()
	point_arms(aim_dir)

	if aim_dir == Vector2.ZERO:
		# Don't fire unless there's actual directional input
		return

	# Tick group timers
	for cd in group_timers:
		group_timers[cd] += delta
		if group_timers[cd] > cd:
			group_timers[cd] -= cd

	var current_time = Time.get_ticks_msec() / 1000.0

	for cd in weapon_groups:
		var timer = group_timers[cd]
		var group = weapon_groups[cd]

		for weapon in group:
			var offset = firing_offsets.get(weapon, 0.0)
			if abs(timer - offset) < delta:
				print("Firing weapon (%s) at time offset %f" % [weapon.name, offset])
				weapon.attempt_fire(aim_dir, current_time)

func get_aim_vector() -> Vector2:
	var x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	var result = Vector2(x, y).normalized()
	#print("res", result)
	return result

func point_arms(aim_dir: Vector2) -> void:
	var dir = aim_dir if aim_dir != Vector2.ZERO else Vector2.DOWN
	for arm in arms:
		arm.target_direction = dir
		arm.is_mirrored = not facing_right
		
func equip_weapon(weapon: Weapon):
	weapons.append(weapon)

	var cd = weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []
		group_timers[cd] = 0.0

	var group = weapon_groups[cd]
	group.append(weapon)

	var index = group.size() - 1
	var offset = (index / group.size()) * cd
	firing_offsets[weapon] = offset
	print("Equipped weapon %s with cooldown %f and offset %f" % [weapon.name, cd, offset])

func find_weapons_recursive(root: Node) -> Array:
	var found := []
	if root is Weapon:
		found.append(root)
	for child in root.get_children():
		found += find_weapons_recursive(child)
	return found

func find_arms_recursive(root: Node) -> Array:
	var found := []
	if root is Arm:
		found.append(root)
	for child in root.get_children():
		found += find_arms_recursive(child)
	return found
