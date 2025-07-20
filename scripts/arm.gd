extends Node2D
class_name Arm

@export var is_mirrored := false  # If body is flipped (facing left)

var _hand_node: Node2D = null
var _actual_aim_direction: Vector2 = Vector2.RIGHT  # Always valid after _ready
var target_direction: Vector2 = Vector2.RIGHT       # World-space target

func _ready():
	_hand_node = get_node_or_null("HandPos")
	if not _hand_node:
		push_warning("No HandPos node found in Arm: " + name)

	# Fallback aim if nothing else is set
	_actual_aim_direction = Vector2.DOWN.rotated(get_parent().global_rotation).normalized()

func _process(_delta):
	var default_base :=  Vector2.UP if is_mirrored else Vector2.DOWN
	var default_world := default_base.rotated(get_parent().global_rotation).normalized()

	_actual_aim_direction = target_direction.normalized() if target_direction != Vector2.ZERO else default_world

	update_rotation()

func update_rotation():
	var dir := _actual_aim_direction
	if dir == Vector2.ZERO:
		dir = (Vector2.UP if is_mirrored else Vector2.DOWN).rotated(get_parent().global_rotation).normalized()

	var local_aim := dir.rotated(-get_parent().global_rotation)
	if is_mirrored:
		local_aim.y *= -1

	rotation = local_aim.angle()

func find_weapon_recursive(node: Node) -> Weapon:
	for child in node.get_children():
		if child is Weapon:
			return child
		var found := find_weapon_recursive(child)
		if found:
			return found
	return null
