extends Node2D
class_name Arm

@export var is_mirrored := false # If body is flipped (facing left)
@export var gun_z_index:= 0
var handPos := Vector2.ZERO # Updated each frame
var _hand_node: Node2D = null

# This is the desired WORLD-SPACE direction from external input (set by CreatureWeaponController)
# When this is Vector2.ZERO, it signals the arm to use the character's default resting direction.
var target_direction := Vector2.RIGHT # Initial default, will be overridden by CreatureWeaponController

var _actual_aim_direction: Vector2 # The direction the arm is currently pointing towards

func _ready():
	for child in get_children():
		if child is Node2D and child.name.begins_with("HandPos"):
			_hand_node = child
			break

	if _hand_node == null:
		push_warning("No HandPos node found in Arm: " + name)
	
	# Initialize _actual_aim_direction to a valid direction.
	# This will be immediately overridden in _process.
	_actual_aim_direction = Vector2.DOWN.rotated(get_parent().global_rotation).normalized() 

func get_hand_pos_gun_z():
	return {"hp":handPos, "gz":gun_z_index}

func _process(delta):
	# Determine the base default direction relative to the character's local "up/down".
	# If character is mirrored (facing left), the resting position is "up" relative to the character.
	# Otherwise (facing right), it's "down" relative to the character.
	var default_base_direction: Vector2
	if is_mirrored:
		default_base_direction = Vector2.UP # Character facing left, arm rests "up"
	else:
		default_base_direction = Vector2.DOWN # Character facing right, arm rests "down"

	# Calculate the character's default world-space resting direction based on parent's rotation.
	var character_default_world_dir = default_base_direction.rotated(get_parent().global_rotation).normalized()

	if target_direction != Vector2.ZERO: # Explicit aim input from CreatureWeaponController
		# Immediately set _actual_aim_direction to the explicit target
		_actual_aim_direction = target_direction.normalized()
	else: # No explicit aim input (target_direction is Vector2.ZERO)
		# Immediately set _actual_aim_direction to the character's determined resting direction
		_actual_aim_direction = character_default_world_dir

	update_rotation()
	update_hand_pos()
func find_weapon_recursive(node: Node) -> Weapon:
	for child in node.get_children():
		if child is Weapon:
			return child
		elif child.get_child_count() > 0:
			var found = find_weapon_recursive(child)
			if found:
				return found
	return null
func update_rotation():
	# If _actual_aim_direction is somehow still zero (shouldn't happen with current logic, but as fallback)
	if _actual_aim_direction == Vector2.ZERO:
		# Fallback to character's default resting direction if _actual_aim_direction is zero
		var default_base_direction: Vector2
		if is_mirrored:
			default_base_direction = Vector2.UP
		else:
			default_base_direction = Vector2.DOWN
		var character_default_world_dir = default_base_direction.rotated(get_parent().global_rotation).normalized()
		_actual_aim_direction = character_default_world_dir

	# Convert the world-space _actual_aim_direction into the arm's local coordinate system.
	# This correctly accounts for the arm's parent's global rotation (e.g., the player's rotation).
	var local_aim = _actual_aim_direction.rotated(-get_parent().global_rotation)
	
	# Apply mirroring for the Y-axis if the character is flipped.
	# This ensures "up" and "down" relative to the arm's local perception are consistent
	# when the arm's parent has a negative X-scale for flipping.
	if is_mirrored:
		local_aim.y *= -1 
	
	# Calculate the rotation based on the (potentially) mirrored local aim vector.
	rotation = local_aim.angle()

func update_hand_pos():
	if _hand_node:
		handPos = _hand_node.global_position
