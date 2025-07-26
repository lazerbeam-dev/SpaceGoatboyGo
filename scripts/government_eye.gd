extends Node2D
class_name GovernmentEye

@export var update_interval := 0.2
@export var coin_update_interval := 2.0
@export var coin_scene: PackedScene
@export var item_target_pool: Dictionary[String, int]
@export var kill_target_pool: Dictionary[String, int]
@export var gov_particles: NodePath
var mission_control: Node = null

@onready var detection_area = self
@onready var world_root: Node = get_tree().root.get_child(0)

var tracked_entities: Dictionary = {}  # Node : {type, last_seen, last_moved, coin, collected, entered_time, health_node}

func _ready():
	Utils.gov_eye = self
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	mission_control = get_node_or_null("MissionControl")
	if not mission_control:
		push_error("GovernmentEye: MissionControl not found as child.")

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

		var type = tracked_entities[entity].get("type", "Unknown")
		if not item_target_pool.has(type):
			continue  # skip coin logic for kill-only targets

		var entry_time = tracked_entities[entity].get("entered_time", 0.0)
		var has_coin = tracked_entities[entity].get("coin") != null
		var coin: Node = null
		if not has_coin:
			coin = coin_scene.instantiate()
			coin.global_position = _get_entity_coin_position(entity)
			coin.target_entity = entity
			coin.collected_signal.connect(_on_coin_collected)
			world_root.add_child(coin)
			tracked_entities[entity]["coin"] = coin
			tracked_entities[entity]["last_moved"] = current_time
			#print("Delayed coin added for:", entity.name)

		var last_seen = tracked_entities[entity].get("last_seen", 0.0)
		if current_time - last_seen >= update_interval:
			tracked_entities[entity]["last_seen"] = current_time

		coin = tracked_entities[entity]["coin"]
		var last_moved = tracked_entities[entity]["last_moved"]
		if coin and is_instance_valid(coin) and (current_time - last_moved >= coin_update_interval):
			coin.global_position = _get_entity_coin_position(entity)
			tracked_entities[entity]["last_moved"] = current_time

func _on_body_entered(body: Node):
	print("[GovEye] body_entered:", body.name, "(", body.get_class(), ") at", body.global_position)
	if not body is SGEntity:
			print("  ❌ Rejected: not SGEntity")
			return
	if body.gov_ignore:
		print("  ❌ Rejected: gov_ignore is true")
		return
	if tracked_entities.has(body):
		print("  ❌ Rejected: already tracked")
		return
	var type = _get_type(body)
	if not item_target_pool.has(type) and not kill_target_pool.has(type):
		print("[GovEye] Disallowed type detected:")
		print("- Entity: ", body.name, " (", body.get_class(), ")")
		print("- Entity type: ", type)
		print("- Has get_entity_type(): ", body.has_method("get_entity_type"))
		print("- Groups: ", body.get_groups())
		print("- Entity code (if exists): ", body.get("entity_code") if body.has_meta("entity_code") or "entity_code" in body else "n/a")
		return

	var entry_time = Time.get_ticks_msec() / 1000.0
	var health_node: Node = null
	if body.has_method("get_health_node"):
		health_node = body.get_health_node()
		if health_node and health_node.has_signal("died"):
			if not health_node.is_connected("died", _on_tracked_entity_died):
				health_node.died.connect(_on_tracked_entity_died.bind(body))

	tracked_entities[body] = {
		"type": type,
		"last_seen": entry_time,
		"last_moved": 0.0,
		"coin": null,
		"collected": false,
		"entered_time": entry_time,
		"health_node": health_node,
	}
func _on_body_exited(body: Node):
	if tracked_entities.has(body):
		var health_node = tracked_entities[body].get("health_node")
		var died_callable = tracked_entities[body].get("died_callable")
		if health_node and died_callable and is_instance_valid(health_node):
			health_node.disconnect("died", died_callable)
		_remove_coin(body)
		tracked_entities.erase(body)

func _on_coin_collected(entity: Node):
	if tracked_entities.has(entity):
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

func _on_tracked_entity_died(entity: Node) -> void:
	if not entity is SGEntity:
		print("[GovEye] Died callback ignored: not an SGEntity:", entity.name)
		return

	var entry = tracked_entities.get(entity)
	if entry == null:
		print("[GovEye] Died callback ignored: not in tracked_entities:", entity.name)
		return

	var type = entry.get("type", "Unknown")
	print("[GovEye] Handling death of entity:", entity.name, "type:", type)

	if kill_target_pool.has(type):
		print("[GovEye] Target eliminated:", {
			"name": entity.name,
			"type": type,
			"entered_time": entry.get("entered_time"),
			"last_seen": entry.get("last_seen")
		})
		if mission_control and mission_control.has_method("register_kill"):
			print("[GovEye] Calling mission_control.register_kill:", type)
			mission_control.register_kill(type)
		else:
			print("[GovEye] mission_control not ready or missing register_kill()")
	else:
		print("[GovEye] Type not in kill_target_pool — won't count as kill:", type)
		print("kill_target_pool keys:", kill_target_pool.keys())

	# Clean up
	_remove_coin(entity)
	tracked_entities.erase(entity)
