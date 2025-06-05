extends Node2D
class_name PathSection

@export var start: Vector2
@export var end: Vector2

@onready var line := Line2D.new()
@onready var collider := CollisionShape2D.new()
@onready var shape := SegmentShape2D.new()

func _ready():
	# Visual line
	line.width = 4
	line.add_point(start)
	line.add_point(end)
	add_child(line)

	# Collision line
	shape.a = start
	shape.b = end
	collider.shape = shape
	var collision = StaticBody2D.new()
	collision.add_child(collider)
	add_child(collision)
