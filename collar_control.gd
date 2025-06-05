### collar_control.gd
extends Node

@onready var player_body := get_parent()

func _ready():
	GameControl.set_player(player_body)

func _physics_process(delta):
	var move_input = Input.get_axis("move_left", "move_right")
	var jump_input = Input.is_action_just_pressed("jump")
	player_body.process_input(move_input, jump_input)
