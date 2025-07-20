extends Node2D
class_name GoatboyControlAntenna

signal goatboy_died(payload: Dictionary)
signal goatboy_control_acquired(payload: Dictionary)
signal goatboy_status_update(payload: Dictionary)
@export var teleporter_path: NodePath
@export var laser_projectile_scene: PackedScene
@export var laser_speed := 600.0
@export var source : Node2D

@export var target: Node2D
var teleporter: Node

func _ready():
	teleporter = get_node_or_null(teleporter_path)

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = find_goatboy()

func send_ping(payload: Dictionary) -> void:
	if not is_instance_valid(target) or laser_projectile_scene == null:
		return

	var laser = laser_projectile_scene.instantiate()
	laser.global_position = global_position
	payload["from_position"] = source.global_position
	var dir = (target.global_position - global_position).normalized()

	if laser.has_method("set_velocity"):
		laser.set_velocity(dir * laser_speed, self)
	else:
		laser.velocity = dir * laser_speed

	if "payload" in laser:
		laser.payload = payload
	else:
		laser.set("payload", payload)

	if "sender" in laser:
		laser.sender = self

	get_tree().current_scene.add_child(laser)

func receive_payload(payload: Dictionary) -> void:
	#print("Antenna received payload: ", payload)
	match payload.get("type"):
		"died":
			emit_signal("goatboy_died", payload)
		"control_acquired":
			emit_signal("goatboy_control_acquired", payload)
		"status":
			emit_signal("goatboy_status_update", payload)

	if teleporter and teleporter.has_method("handle_info_projectile"):
		teleporter.handle_info_projectile(payload)

func receive_impact(impact_payload: Dictionary, _source: Node) -> void:
	receive_payload(impact_payload)

func find_goatboy() -> Node2D:
	for node in get_tree().get_nodes_in_group("GoatboyController"):
		if node is Node2D:
			return node
	return null
