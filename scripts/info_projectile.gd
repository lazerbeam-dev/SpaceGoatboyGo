#extends Area2D
#class_name LaserProjectile
#
#@export var speed := 600.0
#var direction: Vector2 = Vector2.ZERO
#var payload: Dictionary = {}
#
#func _ready():
	#connect("body_entered", _on_body_entered)
	##await get_tree().create_timer(lifetime).timeout
	#set_as_top_level(true)
	#$CollisionShape2D.disabled = false
	#queue_free()
	#
	##print("Laser spawned at:", global_position)
	##print("Payload:", payload)
#
#func _process(delta: float) -> void:
	#position += direction * speed * delta
#
#func _on_body_entered(body: Node) -> void:
	#if not is_instance_valid(body):
		#print("Hit invalid body, ignoring.")
		#queue_free()
		#return
#
	#print("Laser hit body:", body.name, "of type:", body.get_class())
#
	#var collar := body.get_node_or_null("CollarSystem")
	#if collar:
		#print("CollarSystem found on", body.name)
		#if collar.has_method("assess_input"):
			#print("Calling assess_input with payload...")
			#collar.assess_input(payload)
		#else:
			#print("CollarSystem exists but has no assess_input method.")
	#else:
		#print("No CollarSystem found on", body.name)
#
	#queue_free()
