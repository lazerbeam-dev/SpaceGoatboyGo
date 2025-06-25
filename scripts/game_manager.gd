extends Node
class_name GameManager

var score := 0

@onready var score_label: Label = $ScoreLabel

## Scene-wide references — drag them in via inspector
@export var planet: Node2D
@export var pathwright: Node
@export var teleporter_main: Node
@export var player: Node2D

func _ready():
	#_register_globals()
	_update_score_display()

#func _register_globals():
	#IC.planet = planet
	#IC.pathwright = pathwright
	#IC.teleporter_main = teleporter_main
	#IC.player = player


func add_point():
	score += 1
	_update_score_display()

func _update_score_display():
	score_label.text = "You collected " + str(score) + " coins."
