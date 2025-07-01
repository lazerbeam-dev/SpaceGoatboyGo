extends Node2D
class_name InOutCollisionArea

@export var depth_in := 0
@export var inner_area_path: NodePath
@export var outer_area_path: NodePath
@export var visual_reference_sprite_path: NodePath  # Used for z-sorting

var _inner_area: Area2D
var _outer_area: Area2D
var _visual_reference_sprite: Node2D
var _z_shift_states := {}  # Tracks last applied z-offset per model

var body_states := {}  # "inside", "outside", or "between"

signal goatboy_entered_inner(body)
signal goatboy_exited_inner(body)
signal goatboy_entered_outer(body)
signal goatboy_exited_outer(body)

func _ready():
	_inner_area = get_node(inner_area_path)
	_outer_area = get_node(outer_area_path)
	_visual_reference_sprite = get_node_or_null(visual_reference_sprite_path)

	_inner_area.body_entered.connect(_on_inner_entered)
	_inner_area.body_exited.connect(_on_inner_exited)
	_outer_area.body_entered.connect(_on_outer_entered)
	_outer_area.body_exited.connect(_on_outer_exited)

	for body in _inner_area.get_overlapping_bodies():
		body_states[body] = "inside"
		_apply_inner_z_order(body)
		emit_signal("goatboy_entered_inner", body)

func _on_inner_entered(body):
	var prev = body_states.get(body, "unknown")
	body_states[body] = "inside"
	_apply_inner_z_order(body)
	if prev != "inside":
		emit_signal("goatboy_entered_inner", body)

func _on_inner_exited(body):
	var still_in_outer = _outer_area.get_overlapping_bodies().has(body)
	var still_in_inner = _inner_area.get_overlapping_bodies().has(body)
	var prev = body_states.get(body, "unknown")

	if not still_in_inner and not still_in_outer:
		body_states[body] = "outside"
		emit_signal("goatboy_exited_inner", body)
	elif still_in_outer:
		body_states[body] = "outside"
		_apply_outer_z_order(body)
		emit_signal("goatboy_exited_inner", body)

func _on_outer_entered(body):
	# Only act if this body has previously been seen in inner
	if not body_states.has(body):
		return

	var in_inner = _inner_area.get_overlapping_bodies().has(body)
	var prev = body_states.get(body, "unknown")

	if in_inner:
		body_states[body] = "inside"
		return

	body_states[body] = "outside"
	_apply_outer_z_order(body)
	if prev != "outside":
		emit_signal("goatboy_entered_outer", body)

func _on_outer_exited(body):
	# Only act if this body has previously been seen in inner
	if not body_states.has(body):
		return

	var still_in_inner = _inner_area.get_overlapping_bodies().has(body)
	var still_in_outer = _outer_area.get_overlapping_bodies().has(body)
	var prev = body_states.get(body, "unknown")

	if not still_in_outer and not still_in_inner:
		body_states[body] = "inside"
		emit_signal("goatboy_exited_outer", body)
	elif still_in_inner:
		body_states[body] = "inside"
		emit_signal("goatboy_exited_outer", body)

func _apply_inner_z_order(body: Node):
	if _visual_reference_sprite:
		if body.owner == self.owner or body == self:
			return
		var model = body.get_node_or_null("Model")
		if model and model is SmartModel:
			var offset = -depth_in
			if _z_shift_states.get(model, null) != offset:
				model.shift_z_index(offset)
				_z_shift_states[model] = offset

func _apply_outer_z_order(body: Node):
	if _visual_reference_sprite:
		if body.owner == self.owner:
			return
		var model = body.get_node_or_null("Model")
		if model and model is SmartModel:
			var offset = depth_in
			if _z_shift_states.get(model, null) != offset:
				model.shift_z_index(offset)
				_z_shift_states[model] = offset
