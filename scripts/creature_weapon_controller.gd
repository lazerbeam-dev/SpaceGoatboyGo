extends Node2D
class_name CreatureWeaponController

var arm_weapon_map := {}
var weapon_groups := {}
var facing_right := true
var arms := []
var click_to_aim_direction := Vector2.ZERO
var is_mouse_down := false
@export var camera_path: NodePath
var camera: Camera2D
@export var health_node_path: NodePath
var health_node: Node = null
var click_world_target_position := Vector2.ZERO
# Internal firing data structure
class WeaponFireData:
	var weapon: Weapon
	var next_fire_time: float
	var offset: float
	var is_aimed: bool = false
	
	func _init(w: Weapon, offset_val: float):
		weapon = w
		offset = offset_val
		next_fire_time = Time.get_ticks_msec() / 1000.0 + offset_val

var test_weapons: Array[PackedScene] = [
	preload("res://scenes/weapons/shotgun.tscn"),
	preload("res://scenes/weapons/smg.tscn"),
	preload("res://scenes/weapons/grenade_launcher.tscn"),
	preload("res://scenes/weapons/rifle.tscn"),
	preload("res://scenes/weapons/pistol.tscn"),
	preload("res://scenes/weapons/minigun.tscn"),
]
var weapon_index := 0

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and camera:
		is_mouse_down = event.pressed
		if event.pressed:
			print("click")
			# Store the mouse's world position directly when clicked
			click_world_target_position = camera.get_global_mouse_position()

	if event.is_action_pressed("switch_weapon"):
		if arms.is_empty():
			return
		weapon_index = (weapon_index + 1) % test_weapons.size()
		for arm in arms:
			switch_weapon_for_arm(arm, test_weapons[weapon_index])


func _ready():
	set_process_unhandled_input(true)
	print("CreatureWeaponController initialized.")
	arm_weapon_map.clear()
	weapon_groups.clear()
	arms.clear()

	arms = find_arms_recursive(self)
	for arm in arms:
		var weapon_instance = test_weapons[0].instantiate()
		equip_weapon(weapon_instance, arm)
	print("Found %d arms." % arms.size())

	camera = find_parent_camera()
	if not camera:
		push_warning("Camera not found in parent tree.")

	await get_tree().process_frame

	if has_node(health_node_path):
		health_node = get_node(health_node_path)
		health_node.connect("died", Callable(self, "_on_death_signal"))
		print("Connected to died signal.")
	else:
		push_warning("Health node not found at path: %s" % health_node_path)

func get_aim_target_world_position() -> Vector2:
	if is_mouse_down and camera:
		return camera.get_global_mouse_position()

	var x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	var keyboard_input_dir = Vector2(x, y).normalized()

	if keyboard_input_dir == Vector2.ZERO:
		return Vector2.ZERO # No active aim if no keyboard input

	# --- Corrected Keyboard Aiming Logic ---

	# 1. Get the raw keyboard direction (e.g., Vector2(0, -1) for up)
	# 2. Rotate this direction by the camera's *global rotation*.
	#    This ensures that "ui_up" always points "away from the planet"
	#    relative to how the camera is oriented.
	var world_aim_dir_from_keyboard = keyboard_input_dir.rotated(camera.global_rotation)
	
	# 3. Project this rotated direction out from the player's global position
	#    by a fixed distance. This distance should be large enough to be
	#    off-screen or at least well away from the player.
	#    Adjust 500.0 to a suitable aiming distance for your game.
	var aiming_distance = 500.0 # You can make this an @export var if you want to tweak in editor
	return global_position + world_aim_dir_from_keyboard * aiming_distance

# The rest of your code remains the same.
func _process(delta):
	if arm_weapon_map.is_empty():
		return

	var aim_target_world_pos = get_aim_target_world_position()
	
	# Always call point_arms, even if aim_target_world_pos is ZERO.
	# The point_arms function will now handle setting target_direction to ZERO.
	point_arms(aim_target_world_pos)

	# Only proceed with firing logic if there's an active aim target
	if aim_target_world_pos == Vector2.ZERO:
		# If no aim, ensure is_mouse_down is false to prevent accidental firing.
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

			if current_time >= fire_data.next_fire_time and fire_data.is_aimed:
				# Assuming the weapon's "forward" is Vector2.RIGHT when its rotation is 0.
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

func equip_weapon(weapon: Weapon, arm: Arm):
	arm_weapon_map[arm] = weapon

	# Position correctly
	if arm.has_method("get_hand_pos_gun_z"):
		var gnz = arm.get_hand_pos_gun_z()
		print(gnz, "ngutngtnugt")
		weapon.global_position = gnz.hp
		weapon.z_index = gnz.gz
	else:
		weapon.global_position = arm.global_position
	weapon.rotation = 0

	# Group logic with proper offset calculation
	var cd = weapon.cooldown
	if not weapon_groups.has(cd):
		weapon_groups[cd] = []

	var group = weapon_groups[cd]
	var weapon_index_in_group = group.size()
	
	# Calculate offset: evenly distribute weapons across the cooldown period
	# For 2 weapons: offsets are 0.0, 0.5 * cooldown
	# For 3 weapons: offsets are 0.0, 0.33 * cooldown, 0.66 * cooldown, etc.
	var offset = 0.0
	if weapon_index_in_group > 0:
		offset = (float(weapon_index_in_group) / (weapon_index_in_group + 1)) * cd
		
		# Recalculate offsets for all weapons in group to maintain even spacing
		for i in range(group.size()):
			group[i].offset = (float(i) / (weapon_index_in_group + 1)) * cd
			group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + group[i].offset
	
	var fire_data = WeaponFireData.new(weapon, offset)
	group.append(fire_data)

func get_aim_vector() -> Vector2:
	if is_mouse_down and camera:
		var mouse_world_pos = camera.get_global_mouse_position()
		
		# Get the vector from the creature's global position to the mouse's global position
		var to_mouse_vector = mouse_world_pos - global_position
		
		# Rotate this vector by the inverse of the camera's global rotation.
		# This effectively converts the world-space mouse position into a
		# direction relative to the camera's "up" (which is effectively the planet's up).
		# By using -camera.global_rotation, we're un-rotating the vector
		# so it's as if the camera (and the planet) were at 0 rotation.
		return to_mouse_vector.rotated(-camera.global_rotation).normalized()

	var x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	
	# For keyboard input, we also need to account for the camera's rotation
	# to ensure that "up" on the keyboard still means "away from the planet"
	# and "right" means "clockwise around the planet".
	var keyboard_dir = Vector2(x, y).normalized()
	return keyboard_dir.rotated(-camera.global_rotation)


func point_arms(aim_target_world_pos: Vector2):
	# Change starts here: Always iterate through arms
	for arm in arms:
		if aim_target_world_pos == Vector2.ZERO:
			# If no active target, set target_direction to ZERO so Arm script can default
			arm.target_direction = Vector2.ZERO
		else:
			# Calculate the direction from the arm's *global position* to the *world target*
			var dir_to_target = (aim_target_world_pos - arm.global_position).normalized()
			
			# Set the arm's target_direction.
			# The Arm script will then use this global direction to set its local rotation.
			arm.target_direction = dir_to_target
			
		arm.is_mirrored = not facing_right # This logic remains the same regardless of aiming
										  # as it's typically tied to character facing.

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

func find_parent_camera() -> Camera2D:
	var current = get_parent()
	while current:
		var cam := current.get_node_or_null("Camera2D")
		if cam and cam is Camera2D:
			return cam
		current = current.get_parent()
	return null

func drop_weapon(weapon: Weapon):
	if not is_instance_valid(weapon):
		return

	weapon.drop_self()

	# Remove from arm mapping
	var arm = arm_weapon_map.find_key(weapon)
	if arm:
		arm_weapon_map.erase(arm)

	# Remove from weapon groups and recalculate offsets
	var groups_to_clean := []
	for cooldown in weapon_groups:
		var group = weapon_groups[cooldown]
		var new_group := []
		
		# Filter out the dropped weapon
		for fire_data in group:
			if fire_data.weapon != weapon:
				new_group.append(fire_data)
		
		if new_group.is_empty():
			groups_to_clean.append(cooldown)
		else:
			# Recalculate offsets for remaining weapons
			for i in range(new_group.size()):
				new_group[i].offset = (float(i) / new_group.size()) * cooldown
				new_group[i].next_fire_time = Time.get_ticks_msec() / 1000.0 + new_group[i].offset
			weapon_groups[cooldown] = new_group

	# Clean up empty groups
	for cooldown in groups_to_clean:
		weapon_groups.erase(cooldown)

func drop_weapons():
	for weapon in arm_weapon_map.values():
		drop_weapon(weapon)
		
func _on_death_signal():
	drop_weapons()
	set_process(false)
	set_physics_process(false)
