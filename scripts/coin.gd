extends Area2D
class_name Coin

signal collected_signal(target_entity)

@export var burst_lifetime := 0.3  # Seconds to live after bursting
@export var burst_on_body_name := "GoatboyController"  # Or use group check

@onready var sprite: Sprite2D = $Goatbux
@onready var anim: AnimationPlayer = null

var collected := false
var target_entity: Node = null  # This must be set by GovernmentEye when instantiating the coin

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	print("ENTERRR", body)
	if collected:
		return

	if body.name == burst_on_body_name:  # Or use body.is_in_group("player")
		collected = true
		collected_signal.emit(target_entity)
		_play_burst_and_destroy()

func _play_burst_and_destroy():
	if anim and anim.has_animation("burst"):
		anim.play("burst")
	else:
		print("COINGO!")
		sprite.hide()

	await get_tree().create_timer(burst_lifetime).timeout
	queue_free()
