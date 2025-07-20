extends Node2D
class_name InOutCollisionArea

@export var depth_in := 0
@export var inner_area_path: NodePath
@export var outer_area_path: NodePath
@export var visual_reference_sprite_path: NodePath  # Used for z-sorting

var _inner_area: Area2D
var _outer_area: Area2D
var _visual_reference_sprite: Node2D

var _original_z_index_by_model := {}  # model -> base z index
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
		_set_z_index(body, depth_in)
		emit_signal("goatboy_entered_inner", body)

func _on_inner_entered(body):
	var prev = body_states.get(body, "unknown")
	body_states[body] = "inside"
	_set_z_index(body, depth_in)
	if prev != "inside":
		emit_signal("goatboy_entered_inner", body)

func _on_inner_exited(body):
	var in_outer = _outer_area.get_overlapping_bodies().has(body)
	var in_inner = _inner_area.get_overlapping_bodies().has(body)

	if not in_inner and not in_outer:
		body_states[body] = "outside"
		_set_z_index(body, 0)
		emit_signal("goatboy_exited_inner", body)
	elif in_outer:
		body_states[body] = "outside"
		_set_z_index(body, 0)
		emit_signal("goatboy_exited_inner", body)

func _on_outer_entered(body):
	if not body_states.has(body):
		return

	var in_inner = _inner_area.get_overlapping_bodies().has(body)
	if in_inner:
		body_states[body] = "inside"
	else:
		body_states[body] = "outside"
		_set_z_index(body, 0)
		emit_signal("goatboy_entered_outer", body)

func _on_outer_exited(body):
	if not body_states.has(body):
		return

	var in_inner = _inner_area.get_overlapping_bodies().has(body)
	var in_outer = _outer_area.get_overlapping_bodies().has(body)

	if not in_inner and not in_outer:
		body_states[body] = "outside"
		_set_z_index(body, 0)
		emit_signal("goatboy_exited_outer", body)
	elif in_inner:
		body_states[body] = "inside"
		emit_signal("goatboy_exited_outer", body)

func _set_z_index(body: Node, shift: int):
	if body.owner == self.owner:
		return

	var model = body.get_node_or_null("Model")
	if model and model is SmartModel:
		if not _original_z_index_by_model.has(model):
			_original_z_index_by_model[model] = model.z_index
		model.z_index = _original_z_index_by_model[model] + shift
