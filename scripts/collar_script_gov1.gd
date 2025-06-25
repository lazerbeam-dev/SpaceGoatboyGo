extends Node
class_name CollarSystem

@export var laser_scene: PackedScene
@export var reply_speed := 600.0
@export var reply_delay := 0.5
@export var health_node_path: NodePath
@export var arms_node_path: NodePath

var arms_node: Node = null
var health_node: Node = null
var owner_body: Node2D


func _ready():
	owner_body = get_parent() as Node2D
	if not owner_body:
		push_error("CollarSystem must be a child of a Node2D (like Goatboy)")

	if has_node(health_node_path):
		health_node = get_node(health_node_path)
		if health_node.has_signal("died"):
			health_node.connect("died", Callable(self, "_on_owner_died"))
		if health_node.has_signal("health_changed"):
			health_node.connect("health_changed", Callable(self, "_on_health_changed"))
	else:
		push_warning("CollarSystem: Health node not found at path: %s" % health_node_path)


func receive_payload(payload: Dictionary) -> void:
	print("COLLAR received payload:", payload)
	if laser_scene == null or not is_instance_valid(owner_body):
		return

	await get_tree().create_timer(reply_delay).timeout

	var dir := Vector2.UP
	if payload.has("from_position") and typeof(payload["from_position"]) == TYPE_VECTOR2:
		dir = (payload["from_position"] - owner_body.global_position).normalized()

	var reply := {
		"type": "pong",
		"reply_to": payload.get("from", "unknown"),
		"status": "acknowledged",
		"origin": owner_body.name,
		"time": Time.get_unix_time_from_system()
	}

	_spawn_laser(reply, dir)


func _send_status_report(event_type: String, data: Dictionary):
	if laser_scene == null or not is_instance_valid(owner_body):
		return

	var payload := {
		"type": event_type,
		"origin": owner_body.name,
		"data": data,
		"time": Time.get_unix_time_from_system()
	}

	_spawn_laser(payload, Vector2.UP)


func _spawn_laser(payload: Dictionary, direction: Vector2):
	var response = laser_scene.instantiate()
	response.global_position = owner_body.global_position
	response.owner = owner_body

	if response.has_method("set_velocity"):
		response.set_velocity(direction.normalized() * reply_speed, owner_body)
	else:
		response.velocity = direction.normalized() * reply_speed

	if "payload" in response:
		response.payload = payload

	get_tree().current_scene.add_child(response)


func _on_health_changed(new_health: float):
	print("COLLAR: Health changed to %s" % new_health)
	_send_status_report("health_changed", {
		"current_health": new_health
	})

func _on_owner_died():
	print("COLLAR: Owner died!")
	_send_status_report("death", {
		"status": "dead"
	})
	
func init_goatboy(camera: Camera2D, goatboy: Node):
	print("init goatboy")
	var arms = get_node_or_null("../Torso/Arms")
	if arms and arms is CreatureWeaponController:
		print("arms")
		arms.camera = camera
