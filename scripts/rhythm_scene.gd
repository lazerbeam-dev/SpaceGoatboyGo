extends Node2D

@onready var timer = $SpawnTimer
@onready var music = $Music
@onready var clickies = $ClickyContainer.get_children()
func _ready():
	timer.timeout.connect(_on_spawn_beat)
	timer.wait_time = randf_range(1.0, 3.0)
	timer.start()
	music.play()

func _process(_delta):
	for node in clickies:
		var clicky := node as ClickyIndicator
		if clicky:
			clicky.check_key()


func _on_spawn_beat():
	var clicky = clickies[randi() % clickies.size()] as ClickyIndicator
	clicky.spawn_beat()
	timer.wait_time = randf_range(1.0, 3.0)
	timer.start()
