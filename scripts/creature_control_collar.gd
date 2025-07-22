extends Node
class_name CreatureControlCollar

@export var max_jump_charge_time := 0.7
@export var enable_move := false
@export var enable_jump := true
@export var enable_goat_mode := true

var creature: Creature = null
var goatboy: Goatboy = null
var rocketboots: Node = null

var move_axis := 0.0
var rocket_held := false
var goat_mode_held := false

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
		return

	print("Controlling creature: %s" % creature.name)

	if creature is Goatboy:
		goatboy = creature

	rocketboots = creature.get_node_or_null("Rocketboots")
	if rocketboots and rocketboots.has_method("set_rocketing"):
		print("RocketBoots found and ready for external control.")
	elif rocketboots:
		push_warning("RocketBoots found but missing set_rocketing method.")
	else:
		print("No RocketBoots found on creature.")

func _process(delta: float) -> void:
	if not creature:
		return

	if enable_move:
		creature.set_move_input(move_axis)

	if rocketboots and rocketboots.has_method("set_rocketing"):
		rocketboots.set_rocketing(rocket_held)

	if goatboy and enable_goat_mode:
		goatboy.trigger_goat_mode(goat_mode_held)

	# Jump buffer logic
	if buffered_jump_ratio >= 0.0:
		buffered_jump_timer += delta
		if buffered_jump_timer > JUMP_BUFFER_MAX:
			buffered_jump_ratio = -1.0

	if buffered_jump_ratio >= 0.0 and creature.can_jump():
		creature.trigger_jump(buffered_jump_ratio)
		buffered_jump_ratio = -1.0
		buffered_jump_timer = 0.0

	# Jump charging
	if jump_charging:
		jump_charge_time += delta
		jump_charge_time = min(jump_charge_time, max_jump_charge_time)

func handle_move(direction: int):
	move_axis = clamp(direction, -1, 1)

func handle_jump_pressed():
	if enable_jump:
		jump_charging = true
		jump_charge_time = 0.0

func handle_jump_released():
	if not enable_jump or not jump_charging or not is_instance_valid(creature):
		return

	var ratio = clampf(jump_charge_time / max_jump_charge_time, 0.0, 1.0)
	if creature.can_jump():
		creature.trigger_jump(ratio)
	else:
		buffered_jump_ratio = ratio
		buffered_jump_timer = 0.0

	jump_charging = false

func handle_rocket_input(pressed: bool):
	rocket_held = pressed

func handle_goat_mode(pressed: bool):
	goat_mode_held = pressed

func find_parent_creature() -> Creature:
	var node = get_parent()
	while node:
		if node is Creature:
			return node
		node = node.get_parent()
	return null
