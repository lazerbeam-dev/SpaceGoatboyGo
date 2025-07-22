extends CharacterBody2D
class_name SGEntity

@export var entity_code: String = ""  # e.g. "pistol_1", "shroom_2", "goatboy"

func get_entity_type() -> String:
	return entity_code
# need to decide here how to do disabilities, I think the only good way to satck them is a list
# so we will have like dictionary - status effect, timespan
# we update this every 0.3 second
# for now though, just set is_static :
@export var base_scene: String = ""  # e.g. "res://entities/shroom_1.tscn"
@export var gov_ignore: bool = false
@export var size: float = 40.0  # physics size, affects suckability etc
@export var motile: bool = false  # used for AI logic
@export var gravity_strength: float = 800.0
@export var is_static = false
var planet: Node2D
var move_input: Vector2 = Vector2.ZERO
var unique := false  # if true, skip pooling
var base_gravity = 0.0

func _ready() -> void:
	base_gravity = gravity_strength
func get_size() -> float:
	return size
func reset_gravity() -> void:
	gravity_strength = base_gravity
func set_gravity(new_grav: float) -> void:
	gravity_strength = new_grav
# === Serialization ===
func to_json_dict() -> Dictionary:
	return {
		"base_scene": base_scene,
		"size": size,
		"gravity_strength": gravity_strength
	}

func from_json_dict(data: Dictionary) -> void:
	base_scene = data.get("base_scene", base_scene)
	size = data.get("size", size)
	gravity_strength = data.get("gravity_strength", gravity_strength)

# === Smart pooling support ===
func json_relevant_properties() -> Array[String]:
	return ["base_scene", "size", "gravity_strength"]

func get_json_fingerprint() -> String:
	var raw := {}
	for prop in json_relevant_properties():
		raw[prop] = get(prop)
	return JSON.stringify(raw)

func should_pool() -> bool:
	return not unique
