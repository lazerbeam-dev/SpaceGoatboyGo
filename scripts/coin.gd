extends Area2D
class_name Coin

signal collected_signal(target_entity)

@export var value = 1
@export var burst_lifetime := 0.5  # Seconds to live after bursting
@export var burst_on_body_name := "GoatboyController"  # Or use group check

@onready var sprite: Sprite2D = $Goatbux

var collected := false
var target_entity: Node = null  # This must be set by GovernmentEye when instantiating the coin

func _ready():
	body_entered.connect(_on_body_entered)
	collected = false
	#sprite.show()

func _on_body_entered(body: Node):
	pass
func _play_particles():
	$GoldSPark.emitting = true
func _destroy():
	sprite.hide()
	await get_tree().create_timer(burst_lifetime).timeout
	queue_free()
