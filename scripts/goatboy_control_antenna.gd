extends Node2D
class_name GoatboyControlAntenna

@export var target_path: NodePath
@export var teleporter_path: NodePath
@export var ping_interval := 1.69  # seconds, nice and chill
@export var laser_projectile_scene: PackedScene
@export var laser_speed := 600.0

@export var target: Node2D
var teleporter: Node
var time_accum := 0.0

func _ready():
	target = get_node_or_null(target_path)
	if not target:
		print("GoatboyControlAntenna: No target found on path. Will try to auto-acquire.")

	teleporter = get_node_or_null(teleporter_path)
	if not teleporter:
		print("GoatboyControlAntenna: No teleporter found on path.")

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		target = find_goatboy()
		if target:
			print("GoatboyControlAntenna: Acquired target: %s" % target.name)
		else:
			return  # still no target, nothing to do

	time_accum += delta
	if time_accum >= ping_interval:
		time_accum = 0.0
		_send_ping()

func _send_ping():
	if not is_instance_valid(target) or laser_projectile_scene == null:
		return

	var laser = laser_projectile_scene.instantiate()
	laser.global_position = global_position

	var dir = (target.global_position - global_position).normalized()

	if laser.has_method("set_velocity"):
		laser.set_velocity(dir * laser_speed, self)
	else:
		laser.velocity = dir * laser_speed
		if "sender" in laser:
			laser.sender = self

	if "payload" in laser:
		laser.payload = {
			"type": "ping",
			"from": name,
			"time": Time.get_unix_time_from_system(),
			"from_position": global_position
		}

	get_tree().current_scene.add_child(laser)

func receive_payload(payload: Dictionary) -> void:
	print("ANTENNA received payload:", payload)

	if teleporter and teleporter.has_method("handle_info_projectile"):
			teleporter.handle_info_projectile(payload)

func _draw():
	if is_instance_valid(target):
		draw_line(Vector2.ZERO, to_local(target.global_position), Color.RED, 2)

func find_goatboy() -> Node2D:
	for node in get_tree().get_nodes_in_group("GoatboyController"):
		if node is Node2D:
			return node
	return null
