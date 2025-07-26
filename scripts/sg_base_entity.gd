extends CharacterBody2D
class_name SGEntity
signal died
@export var entity_code: String = ""  # e.g. "pistol_1", "shroom_2", "goatboy"

func get_entity_type() -> String:
	return entity_code
# need to decide here how to do disabilities, I think the only good way to satck them is a list
# so we will have like dictionary - status effect, timespan
# we update this every 0.3 second
# for now though, just set is_static :
@export var base_scene: String = ""  # e.g. "res://entities/shroom_1.tscn"
@export var gov_ignore: bool = false
@export var size: float = 40.0  # physics size, affects suckability etc
@export var motile: bool = false  # used for AI logic
@export var gravity_strength: float = 800.0
@export var is_static = false
@export var feet_position : Node2D = null
var piloted_vehicle: SGEntity = null

var death_subscriber: Callable = func(): pass  # placeholder
var planet: Node2D
var move_input: Vector2 = Vector2.ZERO
var unique := false  # if true, skip pooling
var base_gravity = 0.0
func _physics_process(delta: float) -> void:
	# Forward move input to vehicle if we're piloting
	if piloted_vehicle and is_instance_valid(piloted_vehicle):
		piloted_vehicle.move_input = move_input
		rotation = 0
		up_direction = piloted_vehicle.up_direction
func _ready() -> void:
	base_gravity = gravity_strength

	var health = get_health_node()
	if health and health.has_signal("died"):
		health.died.connect(func():
			emit_signal("died")
		)
func get_size() -> float:
	return size
func reset_gravity() -> void:
	gravity_strength = base_gravity
func set_gravity(new_grav: float) -> void:
	gravity_strength = new_grav
func set_move_input(left_right: float) -> void:
	move_input = Vector2(left_right, 0)
func set_move_axis(left_right_up_down: Vector2) -> void:
	move_input = left_right_up_down
# === Serialization ===
func to_json_dict() -> Dictionary:
	return {
		"base_scene": base_scene,
		"size": size,
		"gravity_strength": gravity_strength
	}
func get_health_node() -> DestructibleShape:
	var try = $Health 
	return try if try else null
func from_json_dict(data: Dictionary) -> void:
	base_scene = data.get("base_scene", base_scene)
	size = data.get("size", size)
	gravity_strength = data.get("gravity_strength", gravity_strength)
func get_piloted_vehicle() -> Node:
	return piloted_vehicle
# === Smart pooling support ===
func json_relevant_properties() -> Array[String]:
	return ["base_scene", "size", "gravity_strength"]

func get_json_fingerprint() -> String:
	var raw := {}
	for prop in json_relevant_properties():
		raw[prop] = get(prop)
	return JSON.stringify(raw)

func should_pool() -> bool:
	return not unique
func pilot_vehicle(vehicle: SGEntity, seat_position: Vector2) -> void:
	if vehicle == self:
		push_warning("pilot_vehicle: Cannot pilot self.")
		return
	if not is_instance_valid(vehicle):
		push_warning("pilot_vehicle: Invalid vehicle.")
		return

	# Schedule reparenting safely
	call_deferred("_deferred_pilot_vehicle", vehicle, seat_position)

func _deferred_pilot_vehicle(vehicle: SGEntity, seat_position: Vector2) -> void:
	if not is_instance_valid(vehicle):
		return

	if get_parent():
		get_parent().remove_child(self)
	vehicle.add_child(self)
	print("start piloting!")
	if vehicle.has_method("start_piloting"):
		vehicle.start_piloting(self)
	if feet_position:
		var feet_offset = global_position - feet_position.global_position
		global_position = seat_position + feet_offset
	else:
		global_position = seat_position
	is_static =true
	piloted_vehicle = vehicle
	var vehicle_health = vehicle.get_health_node()
	if vehicle_health:
		death_subscriber = func(): stop_pilot_vehicle()
		vehicle_health.died.connect(death_subscriber)

func stop_pilot_vehicle() -> void:
	if not piloted_vehicle:
		return

	# Call vehicle's stop logic first
	if piloted_vehicle.has_method("stop_piloting"):
		piloted_vehicle.stop_piloting()

	# Disconnect death
	var vehicle_health = piloted_vehicle.get_health_node()
	if vehicle_health and vehicle_health.died.is_connected(death_subscriber):
		vehicle_health.died.disconnect(death_subscriber)

	# Defer reparenting to game root for safety
	var root = get_tree().root.get_child(0)
	var global_pos = global_position  # stash before reparenting
	call_deferred("_deferred_unpilot", root, global_pos)

	piloted_vehicle = null
	death_subscriber = func(): pass
	is_static = not motile
func _deferred_unpilot(target_parent: Node, pos: Vector2) -> void:
	if get_parent():
		get_parent().remove_child(self)
	target_parent.add_child(self)
	global_position = pos
