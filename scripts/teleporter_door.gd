extends Node2D

@export var detector_path: NodePath              # Area2D that detects goatboys
@export var visual_sprite_path: NodePath         # Sprite2D that visually represents the door
@export var collider_path: NodePath              # CollisionShape2D to enable/disable

var detector: Area2D
var sprite: Sprite2D
var collider: CollisionShape2D
var goatboys_inside := {}

func _ready():
	print("[Gate] Ready. Initializing references...")

	detector = get_node_or_null(detector_path)
	sprite = get_node_or_null(visual_sprite_path)
	collider = get_node_or_null(collider_path)

	if not detector:
		push_error("[Gate] Missing detector_path.")
		return
	if not sprite:
		push_error("[Gate] Missing visual_sprite_path.")
		return
	if not collider:
		push_error("[Gate] Missing collider_path.")
		return

	print("[Gate] All nodes found. Connecting signals...")
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

	print("[Gate] Setting initial state (closed)...")
	_update_gate_state()

func _on_body_entered(body):
	print("[Gate] Body entered:", body)
	if _is_goatboy(body):
		#print("[Gate] Recognized Goatboy entered:", body.name)
		goatboys_inside[body] = true
		_update_gate_state()
	else:
		pass
		#print("[Gate] Ignored non-Goatboy:", body.name)

func _on_body_exited(body):
	#print("[Gate] Body exited:", body)
	if _is_goatboy(body):
		#print("[Gate] Recognized Goatboy exited:", body.name)
		goatboys_inside.erase(body)
		_update_gate_state()
	else:
		pass
		#print("[Gate] Ignored non-Goatboy:", body.name)

func _update_gate_state():
	var should_open := not goatboys_inside.is_empty()
	if collider:
		collider.call_deferred("set", "disabled", should_open)  # Remove the 'not' here
	if sprite:
		sprite.visible = not should_open

func _is_goatboy(body: Node) -> bool:
	var match := body.name.contains("Goatboy") or body.is_in_group("goatboy")
	#print("[Gate] Checking if body is Goatboy:", body.name, "=>", match)
	return match
