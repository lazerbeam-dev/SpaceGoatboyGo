extends FloaterCreature
class_name HoverVehicle

var is_piloted := false
var pilot: Node = null
func _physics_process(delta: float) -> void:
	if is_passive() or is_dead:
		move_input = Vector2.ZERO

	## Sync pilot rotation to reference node
	#if is_instance_valid(pilot):
		#pilot.rotation = self.global_rotation

	super._physics_process(delta)
	

func is_passive() -> bool:
	return not is_piloted or is_static or is_stunned or is_dying
func pilot_vehicle(vehicle: SGEntity, seat_position: Vector2) -> void:
	# Ignore if not piloting self
	if vehicle != self:
		push_warning("HoverVehicle: Tried to pilot a different vehicle.")
		return
	
	super.pilot_vehicle(vehicle, seat_position)
	start_piloting(get_parent())  # pilot is the one doing the piloting, now parented


func start_piloting(new_pilot: Node) -> void:
	if not is_instance_valid(new_pilot):
		return
	pilot = new_pilot
	is_piloted = true
	externally_controlled = true
	print("[HoverVehicle] Piloted by: ", pilot.name)

func stop_piloting() -> void:
	var cma = get_node_or_null("ControlMeArea") as ControlMeArea
	if cma and pilot:
		cma.on_pilot_exited(pilot)

	pilot = null
	is_piloted = false
	externally_controlled = false
	move_input = Vector2.ZERO
	

func set_input(input_vec: Vector2) -> void:
	if is_piloted and not is_stunned:
		set_move_axis(input_vec)
