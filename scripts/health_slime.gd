extends DestructibleShape
class_name DestructibleSlime

var split_scene = preload("res://scenes/creatures/slime.tscn")

@export var gloop_path: NodePath = "GloopArea2D/CollisionShape2D"
@export var collider_base_radius := 10.0
@export var invulnerability_duration := 0.5
@export var quantization_unit := 10
@export var starting_health := 40
@export var split_on_damage := false  # toggle to enable slime splitting

var is_invulnerable := false

func _ready():
	super._ready()
	if shape is CircleShape2D:
		collider_base_radius = shape.radius

	health = starting_health
	max_health = starting_health
	update_scale()
	print("Initialized slime with health: %.1f" % health)

func initialize_health(value: float) -> void:
	health = value
	max_health = value
	starting_health = value
	print("→ Health explicitly initialized to %.1f" % value)

func receive_impact(payload: Dictionary, source: Node = null):
	if is_invulnerable or health <= 0:
		print("Ignoring impact: invulnerable or dead.")
		return

	mostRecentPayload = payload
	for modifier in modifiers:
		modifier.apply(self, payload, source)

	var raw_damage: float = payload.get("amount", 0.0)
	var quantized := int(raw_damage / quantization_unit) * quantization_unit
	if quantized <= 0:
		print("Slime took negligible damage (%.1f), skipping." % raw_damage)
		return

	if split_on_damage:
		call_deferred("_spawn_split_slime", quantized)

	health -= quantized
	print("Slime took %d damage → health now %.1f" % [quantized, health])

	if health <= 0:
		print("Slime has died.")
		take_damage(raw_damage, source, payload)
	else:
		update_scale()
		is_invulnerable = true
		get_tree().create_timer(invulnerability_duration).timeout.connect(func():
			is_invulnerable = false
			print("Slime invulnerability ended.")
		)

func _spawn_split_slime(quantized: int) -> void:
	if not split_scene:
		push_warning("No split_scene defined.")
		return

	var new_slime := split_scene.instantiate()
	var ds := new_slime as DestructibleSlime
	if ds:
		ds.initialize_health(quantized)
	else:
		push_warning("Spawned slime is not DestructibleSlime")

	call_deferred("_finalize_spawn", new_slime)

func _finalize_spawn(new_slime: Node) -> void:
	var scene_root := get_tree().get_current_scene()
	if not scene_root:
		push_warning("Could not find current scene root to add split slime.")
		return

	scene_root.add_child(new_slime)
	new_slime.global_position = global_position + Vector2(randf() - 0.5, randf() - 0.5) * 20.0
	print("→ Fully Deferred: Split slime added post-init")

func update_scale():
	var ratio := health / starting_health
	var scale: float = clamp(ratio, 0.1, 1.0)

	if shape is CircleShape2D:
		shape.radius = collider_base_radius * scale
		print("Updated shape radius to %.2f" % shape.radius)

	var gloop_shape := get_node_or_null(gloop_path)
	if gloop_shape and gloop_shape is CollisionShape2D:
		var gloop_circle :CircleShape2D = gloop_shape.shape
		if gloop_circle is CircleShape2D:
			gloop_circle.radius = collider_base_radius * scale
			print("Gloop radius updated to %.2f" % gloop_circle.radius)
		else:
			push_warning("Gloop shape is not CircleShape2D")
	else:
		push_warning("Gloop node not found at path: %s" % gloop_path)

	var model := get_node_or_null(model_path)
	if model:
		model.scale = Vector2.ONE * scale
		print("Model scaled to %.2f" % scale)
	else:
		push_warning("Model node not found at path: %s" % model_path)
		
	var controller := get_node_or_null("Controller")  # adjust path if needed
	if controller and controller.has_variable("jump_velocity"):
		var jump_scale :float= clamp(ratio, 0.1, 1.0)
		controller.jump_strength = controller.jump_strength_base * jump_scale
		print("Jump strength scaled to %.2f" % controller.jump_strength)

	print("Slime updated → health: %.1f / %d, scale: %.2f" % [health, starting_health, scale])
