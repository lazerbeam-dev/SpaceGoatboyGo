extends FloaterCreature
class_name HoverVehicle

var is_piloted := false
var pilot: Node = null

func _physics_process(delta: float) -> void:
	if is_passive() or is_dead:
		move_input = Vector2.ZERO
	super._physics_process(delta)

func is_passive() -> bool:
	return not is_piloted or is_static or is_stunned or is_dying

func start_piloting(new_pilot: Node) -> void:
	if not is_instance_valid(new_pilot):
		return
	pilot = new_pilot
	is_piloted = true
	externally_controlled = true
	print("[HoverVehicle] Piloted by: ", pilot.name)

func stop_piloting() -> void:
	print("[HoverVehicle] Pilot released: ", pilot.name if pilot else "None")
	pilot = null
	is_piloted = false
	externally_controlled = false
	move_input = Vector2.ZERO

func set_input(input_vec: Vector2) -> void:
	if is_piloted and not is_stunned:
		set_move_input(input_vec)
