extends Node2D

@export var max_size_to_suck := 10.0
@export var do_explosion: bool = true
@export var suck_strength := 800.0

@onready var suck_area: Area2D = $SuckArea
@onready var processor: Node2D = $Processor

var sucked_items: Array = []
var is_enabled := false

func _ready():
	print("[Vacuum] Ready.")
	suck_area.body_entered.connect(_on_body_entered)
	suck_area.body_exited.connect(_on_body_exited)

	for body in suck_area.get_overlapping_bodies():
		print("[Vacuum] Pre-existing overlap: ", body.name)
		_on_body_entered(body)

func enable():
	is_enabled = true
	print("[Vacuum] Enabled.")

func disable():
	is_enabled = false
	print("[Vacuum] Disabled. Clearing suck state.")
	for item in sucked_items.duplicate():
		if is_instance_valid(item):
			if item is SGEntity:
				item.reset_gravity()
				item.gov_ignore = false
	sucked_items.clear()

func _on_body_entered(body: Node):
	if not is_enabled or body in sucked_items:
		return
	if not (body is CharacterBody2D) or body == self:
		return
	if body is SGEntity and body.size >= max_size_to_suck:
		return

	print("[Vacuum] Accepting: ", body.name)
	sucked_items.append(body)
	
	if body is SGEntity:
		body.set_gravity(0.0)
		body.gov_ignore = true
		var it = get_coin_for_item(body)
		if it:
			it._play_particles()

func _on_body_exited(body: Node):
	if not is_enabled:
		return
	if body in sucked_items:
		sucked_items.erase(body)
		print("[Vacuum] Exited suck area: ", body.name)
		if body is SGEntity:
			body.reset_gravity()
			body.gov_ignore = false

func _physics_process(delta: float) -> void:
	if not is_enabled:
		return

	for i in range(sucked_items.size() - 1, -1, -1):
		var item = sucked_items[i]
		if not is_instance_valid(item):
			sucked_items.remove_at(i)
			continue

		var dist = item.global_position.distance_to(processor.global_position)

		if dist < 21:
			sucked_items.remove_at(i)
			_process_item(item)
			continue

		if item is SGEntity and item.size < max_size_to_suck:
			var dir = (processor.global_position - item.global_position).normalized()
			item.velocity = Vector2.ZERO
			item.global_position += dir * suck_strength * delta
func get_coin_for_item(item: Node) -> Coin:
	var gov_eye = Utils.gov_eye
	if gov_eye and is_instance_valid(gov_eye) and gov_eye.tracked_entities.has(item):
		var entry = gov_eye.tracked_entities[item]
		var coin = entry.get("coin")
		if coin and is_instance_valid(coin):
			return coin
	return null
func _process_item(item: Node):
	print("[Vacuum] Processing: ", item.name)

	var gov_eye = Utils.gov_eye
	if gov_eye and is_instance_valid(gov_eye) and gov_eye.tracked_entities.has(item):
		var entry = gov_eye.tracked_entities[item]
		var coin = entry.get("coin")
		if coin and is_instance_valid(coin) and not entry.get("collected", false):
			entry["collected"] = true
			coin.collected_signal.emit(item)
			Utils.current_collar.bump_money(coin.value)
			if do_explosion:
				coin._destroy()

	if item.has_method("get_json_fingerprint"):
		print("🧹 SUCKED ITEM DEATH (fingerprint): ", item.get_json_fingerprint())
	else:
		print("🧹 SUCKED ITEM (no fingerprint): ", item.name, item.get_class())

	item.queue_free()
