@tool
extends Node2D
class_name CornerSpritesPositioner

@export var curve_path: NodePath
@export var step := 5.0
@export var center := Vector2.ZERO
@export var line_width := 64.0
@export var min_corner_angle_degrees := 64.0

@export var or_sprite: Texture2D
@export var ol_sprite: Texture2D
@export var ir_sprite: Texture2D
@export var il_sprite: Texture2D

@export var shared_material: Material  # Shared material for all placed corner sprites

@export var analyze_now := false:
	set(value):
		analyze_now = false
		analyze()

var last_corner_pos := Vector2.INF

func _ready():
	if not Engine.is_editor_hint():
		analyze()

func analyze():
	clear_children()
	last_corner_pos = Vector2.INF

	var curve_owner := get_node_or_null(curve_path)
	if not curve_owner or not curve_owner is Path2D:
		push_error("Invalid or missing Path2D.")
		return

	var curve: Curve2D = curve_owner.curve
	var length := curve.get_baked_length()
	var segments := int(length / step)

	for i in range(1, segments - 1):
		var p0 = curve.sample_baked((i - 1) * step)
		var p1 = curve.sample_baked(i * step)
		var p2 = curve.sample_baked((i + 1) * step)

		var v1 = (p1 - p0).normalized()
		var v2 = (p2 - p1).normalized()

		var turn_angle = v1.angle_to(v2)
		if abs(turn_angle) < deg_to_rad(min_corner_angle_degrees):
			continue

		var to_center = (p1 - center).normalized()
		var outward_normal = Vector2(-to_center.y, to_center.x)
		var is_outer = v2.cross(outward_normal) > 0

		var label := ""
		if turn_angle > 0:
			label = "OR" if not is_outer else "OL"
		else:
			label = "IR" if is_outer else "IL"

		if p1.distance_to(last_corner_pos) >= line_width * 1.5:
			match label:
				"OR":
					#NOTE THIS IS NECESSARY
					var radial_before = abs(v1.dot(to_center))
					var radial_after = abs(v2.dot(to_center))
					var becoming_more_tangent = radial_after < radial_before
					if becoming_more_tangent:
						# Post-hoc correction: it's really an OL
						place_corner_sprite(p1, v2, ol_sprite, false)
					else:
						place_corner_sprite(p1, v1, or_sprite, false)
				"OL":
					var tangent := Vector2(-to_center.y, to_center.x)
					var best_v :Vector2 = v2
					var best_dot :float = abs(v2.dot(tangent))

					# Lookahead: find best direction (most tangential), but keep position
					for j in range(1, 4):
						var next_i := i + j
						if next_i + 1 >= segments:
							break

						var ahead_p1 = curve.sample_baked(next_i * step)
						var ahead_p2 = curve.sample_baked((next_i + 1) * step)
						var ahead_v = (ahead_p2 - ahead_p1).normalized()
						var ahead_dot = abs(ahead_v.dot((ahead_p1 - center).normalized()))
						if ahead_dot < best_dot:
							best_dot = ahead_dot
							best_v = ahead_v

					place_corner_sprite(p1, best_v, ol_sprite, false)

				"IR":
					place_corner_sprite(p1, v1, ir_sprite, false)
				"IL":
					place_corner_sprite(p1, -v2, il_sprite, false)

			last_corner_pos = p1

func place_corner_sprite(position: Vector2, direction: Vector2, texture: Texture2D, flip_h: bool):
	if not texture:
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.rotation = direction.angle()
	sprite.scale = Vector2.ONE * (line_width / texture.get_width())
	sprite.flip_h = flip_h
	sprite.centered = true

	if shared_material:
		sprite.material = shared_material

	add_child(sprite)

func place_corner_label(position: Vector2, text: String):
	var label := Label.new()
	label.text = text
	label.scale = Vector2.ONE * 0.5
	label.position = position + Vector2(0, -line_width * 0.6)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.z_index = 999
	add_child(label)

func clear_children():
	for c in get_children():
		c.queue_free()
