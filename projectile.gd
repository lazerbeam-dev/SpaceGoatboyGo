extends Area2D

var velocity := Vector2.ZERO
@export var speed := 600.0
@export var lifetime := 2.0
@export var colour := "blue";

func set_velocity(v: Vector2) -> void:
	velocity = v

func _on_body_entered(body):
	print("body entered!", body)
	if "take_damage" in body:
		body.take_damage(10)
	queue_free()

func _ready():
	connect("body_entered", _on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	position += velocity * delta
