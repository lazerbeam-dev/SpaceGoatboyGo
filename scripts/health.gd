extends CollisionShape2D
class_name DestructibleShape

@export var max_health := 10.0
var health: float = 10.0
var modifiers := []
@export var poolable := true
@export var model_path: NodePath

var mostRecentPayload: Dictionary

signal damaged(amount: float, source)
signal died
signal last_frame_on_the_plane
signal received_impact

func get_health_ratio():
	return health/max_health

func _ready():
	health = max_health

func receive_impact(payload: Dictionary, source: Node = null):
	if health < 0:
		return
	
	# Safely store a deep copy of the original payload
	mostRecentPayload = payload.duplicate(true)
	set_meta("mostRecentPayload", mostRecentPayload)

	#print("DestructibleShape: Received payload:", mostRecentPayload)

	# Allow modifiers to mutate payload if needed
	for modifier in modifiers:
		modifier.apply(self, mostRecentPayload, source)

	var damage: float = mostRecentPayload.get("amount", 0.0)
	emit_signal("received_impact", payload, source)
	if damage > 0:
		take_damage(damage, source, mostRecentPayload)

func take_damage(amount: float, source: Node, _payload: Dictionary):
	emit_signal("damaged", amount, source)
	health -= amount
	if health <= 0:
		_destroy_self()

func _destroy_self():
	emit_signal("last_frame_on_the_plane")
	call_deferred("_really_destroy_self")

func _really_destroy_self():
	var body := get_parent()
	#print("DestructibleShape: Destroying parent")

	emit_signal("died")

	if body and body is CharacterBody2D:
		if body.has_method("die"):
			body.die()

	var model := get_node_or_null(model_path)
	if model and model.has_method("begin_dissolve"):
		#print("DestructibleShape: Triggering model dissolve")
		model.begin_dissolve(mostRecentPayload)

	await get_tree().create_timer(0.5).timeout
	body.queue_free()
