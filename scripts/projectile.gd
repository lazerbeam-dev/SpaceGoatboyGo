extends Area2D

var velocity := Vector2.ZERO
@export var speed := 600.0
@export var lifetime := 5.0
@export var damage := 5.0
@export var colour := "blue"
@export var payload := {}
@export var sender: Node = null  # Node to ignore on collision

func set_velocity(v: Vector2, p_sender: Node = null) -> void:
	velocity = v
	sender = p_sender

func _on_body_entered(body):
		# Ignore sender and their piloted vehicle
	if body == sender:
		return

	# If sender is a Creature and this is their vehicle, ignore
	if sender and sender.has_method("get_piloted_vehicle"):
		#print("PILIOBODY BODY", body, "ONON:  ", body.owner, "SNOEOEO: ", sender.get_piloted_vehicle())
		if sender.get_piloted_vehicle() and (body == sender.get_piloted_vehicle() or body.owner == sender.get_piloted_vehicle()):
			return
	var target: Node = null
	
	# Check if body is DestructibleShape or valid StaticBody2D with method
	if body.has_method("receive_impact"):
		target = body
	else:
		# Check for DestructibleShape in children
		for child in body.get_children():
			if child is DestructibleShape:
				target = child
				break

	if target and is_instance_valid(sender):
		var impact_payload := {
			"amount": damage,
			"source": sender,
			"direction": velocity.normalized(),
			"position": global_position,
			"type": "projectile",
			"colour": colour,
		}

		for key in payload.keys():
			impact_payload[key] = payload[key]

		target.receive_impact(impact_payload, sender)

	queue_free()



func _ready():
	connect("body_entered", _on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	position += velocity * delta
