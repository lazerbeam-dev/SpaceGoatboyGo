extends Node
class_name InputManager

func _ready():
	print("InputManager ready and listening.")
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	var collar = Utils.get_active_collar()
	if not collar:
		return

	var collar_input = collar.get_node_or_null("CollarArmsControl")
	var collar_move = collar.get_node_or_null("CollarCreatureControl")

	# Fire
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if collar_input and collar_input.has_method("handle_input_fire_request"):
			collar_input.handle_input_fire_request(event)

	# Jump
	if event.is_action_pressed("jump"):
		if collar_move and collar_move.has_method("handle_jump_pressed"):
			collar_move.handle_jump_pressed()
	elif event.is_action_released("jump"):
		if collar_move and collar_move.has_method("handle_jump_released"):
			collar_move.handle_jump_released()

	# Rocket (W key / up)
	if event.is_action_pressed("move_up"):
		if collar_move and collar_move.has_method("handle_rocket_input"):
			collar_move.handle_rocket_input(true)
	elif event.is_action_released("move_up"):
		if collar_move and collar_move.has_method("handle_rocket_input"):
			collar_move.handle_rocket_input(false)

	# Goat mode
	if event.is_action_pressed("goat_mode"):
		if collar_move and collar_move.has_method("handle_goat_mode"):
			collar_move.handle_goat_mode(true)
	elif event.is_action_released("goat_mode"):
		if collar_move and collar_move.has_method("handle_goat_mode"):
			collar_move.handle_goat_mode(false)

	# Move (L/R)
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right") \
	or event.is_action_released("move_left") or event.is_action_released("move_right"):
		if collar_move and collar_move.has_method("handle_move"):
			var dir := Input.get_axis("move_left", "move_right")
			collar_move.handle_move(dir)
