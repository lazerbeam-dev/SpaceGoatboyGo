extends Node2D
class_name Arm

@export var default_direction := Vector2.RIGHT
@export var is_mirrored := false  # If body is flipped (facing left)

var handPos := Vector2.ZERO  # Updated each frame
var _hand_node: Node2D = null

var target_direction := Vector2.RIGHT  # Arm rotates toward this

func _ready():
	# Find first child with name starting with "HandPos"
	for child in get_children():
		if child is Node2D and child.name.begins_with("HandPos"):
			_hand_node = child
			break

	if _hand_node == null:
		push_warning("No HandPos node found in Arm: " + name)

func get_hand_pos():
	return handPos

func _process(_delta):
	update_rotation()
	update_hand_pos()

func update_rotation():
	if target_direction == Vector2.ZERO:
		return

	var aim = target_direction.normalized()
	if is_mirrored:
		aim.x *= -1

	rotation = aim.angle()

func update_hand_pos():
	if _hand_node:
		handPos = _hand_node.global_position
