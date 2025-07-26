extends Area2D
class_name ControlMeArea

@export var seat_offset := Vector2.ZERO  # Local seat position on vehicle
@export var cooldown_duration := 3.0  # seconds to block re-piloting

@onready var vehicle: SGEntity = get_parent() as SGEntity
var current_pilot: SGEntity = null
var last_pilot: SGEntity = null

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(vehicle) or current_pilot or last_pilot == body:
		return
	if body is SGEntity and body.has_method("pilot_vehicle") and body != vehicle:
		current_pilot = body
		last_pilot = body
		var global_seat = to_global(seat_offset)
		body.call_deferred("pilot_vehicle", vehicle, global_seat)

func on_pilot_exited(entity: SGEntity) -> void:
	if current_pilot == entity:
		current_pilot = null
	if last_pilot == entity:
		# Start a timer to clear last_pilot
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = cooldown_duration
		timer.timeout.connect(_clear_last_pilot.bind(entity))
		add_child(timer)
		timer.start()

func _clear_last_pilot(entity: SGEntity) -> void:
	if last_pilot == entity:
		last_pilot = null
