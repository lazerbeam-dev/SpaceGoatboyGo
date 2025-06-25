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
	if body == sender:
		return  # Ignore collisions with sender

	var target: Node = null

	# Check if body is DestructibleShape
	if body is DestructibleShape:
		target = body
	else:
		# Check for DestructibleShape in children
		for child in body.get_children():
			if child is DestructibleShape:
				target = child
				break

	if target:
		var impact_payload := {
			"amount": damage,
			"source": sender,
			"direction": velocity.normalized(),
			"position": global_position,
			"type": "projectile",
			"colour": colour,
		}
		
		# Manually merge payload entries
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
