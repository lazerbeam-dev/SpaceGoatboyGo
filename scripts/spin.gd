extends Node2D

@export var spin_speed := 1.0  # Radians per second

func _process(delta):
	rotation += spin_speed * delta
