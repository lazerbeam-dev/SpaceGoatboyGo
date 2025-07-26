extends Node

@export var spawn_time := 300.0
@export var boss_scene: PackedScene
@export var minion_scene: PackedScene
@export var minion_count := 5
@export var spawn_location: NodePath

var time_passed := 0.0
var boss_spawned := false

@onready var spawn_point := get_node(spawn_location)

func _process(delta):
	if boss_spawned:
		return
	time_passed += delta
	if time_passed >= spawn_time:
		_spawn_boss()
		boss_spawned = true

func _spawn_boss():
	print("BOSS TIME")

	# Spawn boss
	var boss = boss_scene.instantiate()
	spawn_point.add_child(boss)
	boss.global_position = spawn_point.global_position

	# Spawn entourage
	for i in minion_count:
		var minion = minion_scene.instantiate()
		spawn_point.add_child(minion)
		minion.global_position = spawn_point.global_position + (Vector2(randf() * 80 - 40, randf() * 40 - 20) * 5)

	# Screen shake
	Utils.shake_screen(5, 3)

	# Create BossMission in code
	var boss_mission := BossMission.new()
	boss_mission.description = "Eliminate the very important shroom"
	boss_mission.boss = boss

	var collar_main :CollarMain= Utils.get_active_collar()
	if collar_main and collar_main.has_method("set_override_mission"):
		collar_main.set_override_mission(boss_mission)
