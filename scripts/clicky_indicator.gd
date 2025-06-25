class_name ClickyIndicator
extends ColorRect

@export var key_code: String = "w"  # one of "w", "a", "s", etc.
@onready var label = $Label

var is_active = false
var success = false
var beat_window = 0.4

func _ready():
	label.text = key_code.to_upper()
	visible = false

func spawn_beat():
	is_active = true
	success = false
	color = Color.WHITE
	visible = true
	start_timing()

func start_timing():
	await get_tree().create_timer(beat_window).timeout
	if not success:
		color = Color.RED
		print("Miss:", key_code)
	await get_tree().create_timer(0.3).timeout
	visible = false
	is_active = false

func check_key():
	if is_active and Input.is_action_just_pressed(key_code):
		success = true
		color = Color.GREEN
		print("Hit:", key_code)
