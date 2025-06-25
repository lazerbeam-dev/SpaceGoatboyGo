@tool
extends Node2D
class_name RadialParallaxPlanet

@export var center := Vector2.ZERO
@export var radius := 1200.0
@export var section_count := 64
@export var parallax_factor := 0.5
@export var camera_path: NodePath

@export var frequency_1 := 2.0
@export var amplitude_1 := 40.0
@export var frequency_2 := 1.0
@export var amplitude_2 := 20.0

@export var color := Color(0.6, 0.7, 1.0)
@export var width := 3.0
@export var bake_now := false:
	set(value):
		bake_now = false
		update_points()
		queue_redraw()

var polygon_points := PackedVector2Array()

func _ready():
	update_points()
	queue_redraw()

func _process(_delta):
	if not Engine.is_editor_hint():
		update_points()
		queue_redraw()

func update_points():
	var cam_angle := 0.0

	if not Engine.is_editor_hint() and camera_path != NodePath(""):
		var cam := get_node_or_null(camera_path)
		if cam:
			cam_angle = (cam.global_position - center).angle()

	var poly := PackedVector2Array()

	for i in range(section_count):
		var base_theta = TAU * i / section_count
		var theta = base_theta + cam_angle * parallax_factor

		var wave = sin(theta * frequency_1) * amplitude_1 \
				 + sin(theta * frequency_2) * amplitude_2

		var r = radius + wave
		var pos = center + Vector2.RIGHT.rotated(theta) * r
		poly.append(pos)

	polygon_points = poly

func _draw():
	if polygon_points.size() < 2:
		return

	for i in range(polygon_points.size()):
		var a = polygon_points[i]
		var b = polygon_points[(i + 1) % polygon_points.size()]
		draw_line(a, b, color, width)
