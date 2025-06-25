extends Node
class_name CreatureControlCollar

@export var max_jump_charge_time := 0.7
@export var enable_move := true
@export var enable_jump := true
@export var enable_goat_mode := true  # Optional toggle

var creature: Creature = null
var goatboy: Goatboy = null  # Optional cast
var jump_charging: bool = false
var jump_charge_time: float = 0.0
var buffered_jump_ratio := -1.0
var buffered_jump_timer := 0.0
const JUMP_BUFFER_MAX := 0.5

func _ready():
	print("CreatureControlCollar initialized.")

	creature = find_parent_creature()
	if not creature:
		push_error("CreatureControlCollar could not find a parent Creature node.")
	else:
		print("Controlling creature: %s" % creature.name)
		if creature is Goatboy:
			goatboy = creature

func _process(delta: float) -> void:
	if not creature:
		return

	if enable_move:
		var dir = Input.get_axis("move_left", "move_right")
		creature.set_move_input(dir)

	# Jump buffering
	if buffered_jump_ratio >= 0.0:
		buffered_jump_timer += delta
		if buffered_jump_timer > JUMP_BUFFER_MAX:
			buffered_jump_ratio = -1.0

	if buffered_jump_ratio >= 0.0 and creature.can_jump():
		creature.trigger_jump(buffered_jump_ratio)
		buffered_jump_ratio = -1.0
		buffered_jump_timer = 0.0

	# Jump charging
	if enable_jump:
		if Input.is_action_just_pressed("jump"):
			jump_charging = true
			jump_charge_time = 0.0

		elif Input.is_action_pressed("jump") and jump_charging:
			jump_charge_time += delta
			jump_charge_time = min(jump_charge_time, max_jump_charge_time)

		elif Input.is_action_just_released("jump") and jump_charging:
			var ratio := clampf(jump_charge_time / max_jump_charge_time, 0.0, 1.0)

			if creature.can_jump():
				creature.trigger_jump(ratio)
			else:
				buffered_jump_ratio = ratio
				buffered_jump_timer = 0.0

			jump_charging = false

	# Goat mode input
	if enable_goat_mode and goatboy:
		if Input.is_action_pressed("goat_mode"):
			goatboy.trigger_goat_mode(true)
		else:
			goatboy.trigger_goat_mode(false)

func find_parent_creature() -> Creature:
	var node = get_parent()
	while node:
		if node is Creature:
			return node
		node = node.get_parent()
	return null
