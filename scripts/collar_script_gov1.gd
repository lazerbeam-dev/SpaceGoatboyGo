extends Node2D
class_name CollarSystem

@export var laser_scene: PackedScene
@export var reply_speed := 600.0
@export var control_tower: Node
@export var my_id :String=""

var owner_body: Node2D
var controller_node: Node
var model_node: Node
var health_node: Node
var drop_node: Node2D
var arms_node: Node

var awaiting_death_ack := false

func _ready():
	initialize()

func initialize():
	owner_body = Util.get_node_parent_of_type(self, "CharacterBody2D") as Node2D
	if not owner_body:
		push_error("CollarSystem: Could not find owner body")
		return

	controller_node = $".."
	drop_node = $".."
	model_node = owner_body.get_node_or_null("Model")
	arms_node = owner_body.get_node_or_null("Model/Torso/Arms")

	health_node = owner_body.get_node_or_null("Health")
	if health_node:
		if health_node.has_signal("died"):
			health_node.connect("died", Callable(self, "_on_owner_died"))
		if health_node.has_signal("last_frame_on_the_plane"):
			health_node.connect("last_frame_on_the_plane", Callable(self, "_on_last_frame_cleanup"))
		if health_node.has_signal("received_impact"):
			health_node.connect("received_impact", Callable(self, "receive_payload"))
	my_id = Util.generate_guid()

func send_laser(payload: Dictionary, direction: Vector2, sender):
	if not is_instance_valid(sender): 
		sender = controller_node
	if not laser_scene:
		return
	var laser = laser_scene.instantiate()
	laser.global_position = global_position
	payload["time"] = Time.get_unix_time_from_system()

	if laser.has_method("set_velocity"):
		laser.set_velocity(direction.normalized() * reply_speed)
	else:
		laser.velocity = direction.normalized() * reply_speed
	if "payload" in laser:
		laser.payload = payload
	else:
		laser.set("payload", payload)
	laser.sender = sender
	get_tree().current_scene.call_deferred("add_child", laser)


func _on_last_frame_cleanup():
	if controller_node:
		controller_node.on_last_frame()
	if drop_node:
		Util.drop_node_as_wrapped_item(drop_node)
	if model_node and model_node.has_method("remove_sprite_for_node"):
		print("remove sprite for node")
		model_node.remove_sprite_for_node(controller_node)

func _on_owner_died():
	awaiting_death_ack = true
	_on_last_frame_cleanup()
func receive_payload(payload: Dictionary, _source) -> void:
	if controller_node and controller_node.has_method("handle_control_payload"):
		controller_node.handle_control_payload(payload)
