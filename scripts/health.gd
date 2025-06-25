extends CollisionShape2D
class_name DestructibleShape

@export var max_health := 10.0
var health: float = 10.0
var modifiers := []
@export var poolable := true
var mostRecentPayload :Dictionary

signal damaged(amount: float, source)
signal died

func _ready():
	health = max_health

func receive_impact(payload: Dictionary, source: Node = null):
	if health < 0:
		return
	
	mostRecentPayload = payload
	for modifier in modifiers:
		modifier.apply(self, payload, source)

	var damage: float = payload.get("amount", 0.0)
	take_damage(damage, source, payload)

func take_damage(amount: float, source: Node, payload: Dictionary):
	emit_signal("damaged", amount, source)
	health -= amount
	if health <= 0:
		_destroy_self()

func _destroy_self():
	call_deferred("_really_destroy_self")

func _really_destroy_self():
	var body := get_parent()
	print("die health")
	emit_signal("died")
	if body and body is CharacterBody2D:
		if body.has_method("die"):
			body.die()
		elif "gravity_scale" in body:
			body.gravity_scale = 0.0
	
	var model := body.get_node_or_null("Model")
	if model and model.has_method("begin_dissolve"):
		model.begin_dissolve(mostRecentPayload)

	await get_tree().create_timer(1.1).timeout
	queue_free()
