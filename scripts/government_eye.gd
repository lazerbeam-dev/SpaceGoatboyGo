extends Node2D
class_name GovernmentEye
@export var update_interval := 0.2
@export var coin_update_interval := 2.0
@export var coin_scene: PackedScene
@export var target_pool: Dictionary[String, int]
@export var gov_particles: NodePath  # Drag your GovernmentParticles node here in editor

@onready var detection_area = self
@onready var world_root: Node = get_tree().root.get_child(0)
#@onready var particles := get_node(gov_particles)

var tracked_entities: Dictionary = {}  # Node : {type, last_seen, last_moved, coin, collected, entered_time}

func _ready():
	Utils.gov_eye = self
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _process(_delta):
	var current_time = Time.get_ticks_msec() / 1000.0

	for entity in tracked_entities.keys():
		if not is_instance_valid(entity):
			_remove_coin(entity)
			tracked_entities.erase(entity)
			continue
		if entity.gov_ignore:
			continue
		if tracked_entities[entity].get("collected", false):
			continue

		var entry_time = tracked_entities[entity].get("entered_time", 0.0)
		var has_coin = tracked_entities[entity].get("coin") != null
		var coin :Node=null
		if not has_coin:
			coin = coin_scene.instantiate()
			coin.global_position = _get_entity_coin_position(entity)
			coin.target_entity = entity
			coin.collected_signal.connect(_on_coin_collected)
			world_root.add_child(coin)
			tracked_entities[entity]["coin"] = coin
			tracked_entities[entity]["last_moved"] = current_time
			print("Delayed coin added for:", entity.name)

		var last_seen = tracked_entities[entity].get("last_seen", 0.0)
		if current_time - last_seen >= update_interval:
			tracked_entities[entity]["last_seen"] = current_time

		coin = tracked_entities[entity]["coin"]
		var last_moved = tracked_entities[entity]["last_moved"]
		if coin and is_instance_valid(coin) and (current_time - last_moved >= coin_update_interval):
			coin.global_position = _get_entity_coin_position(entity)
			tracked_entities[entity]["last_moved"] = current_time

func _on_body_entered(body: Node):
	if not body is SGEntity:
		return
	if body.gov_ignore:
		return
	if tracked_entities.has(body):
		return

	var type = _get_type(body)
	if not target_pool.has(type):
		return

	tracked_entities[body] = {
		"type": type,
		"last_seen": Time.get_ticks_msec() / 1000.0,
		"last_moved": 0.0,
		"coin": null,
		"collected": false,
		"entered_time": Time.get_ticks_msec() / 1000.0,
	}
	print("Tracking entity (delayed):", body.name, "as", type)

func _on_body_exited(body: Node):
	_remove_coin(body)
	tracked_entities.erase(body)

func _on_coin_collected(entity: Node):
	if tracked_entities.has(entity):
		var coin = tracked_entities[entity].get("coin")
		_remove_coin(entity)
		tracked_entities.erase(entity)

func _remove_coin(body: Node) -> void:
	if tracked_entities.has(body):
		tracked_entities[body]["collected"] = true
		var coin = tracked_entities[body].get("coin")
		if coin and is_instance_valid(coin):
			coin.queue_free()

func _get_type(entity: Node) -> String:
	return entity.get_entity_type() if entity.has_method("get_entity_type") else "Unknown"

func _get_entity_coin_position(entity: Node2D) -> Vector2:
	return entity.global_position
