# cog.gd
extends RefCounted
class_name COG

var name: String
var rng: RandomNumberGenerator
var state := {}
var memory := []

func _init(_name: String, seed: int):
	name = _name
	rng = RandomNumberGenerator.new()
	rng.seed = seed

func get_tick_action(time: int):
	return null

func on_event(event: Dictionary) -> void:
	pass
