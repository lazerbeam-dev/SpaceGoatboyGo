extends Node

## Core shared nodes
var planet: Node2D = null
var pathwright: Node = null
var teleporter_main: Node = null
var player: Node = null

## Initialization flags (to prevent bugs)
var is_ready := false

func _ready():
	is_ready = true
	print("Global singleton ready.")

## Optional helpers
func require(name: String, value: Node) -> void:
	if not is_ready:
		await ready  # wait until _ready is hit
	if not value:
		push_error("IC: Attempted to register '%s' as null!" % name)
		return
	match name:
		"planet": planet = value
		"pathwright": pathwright = value
		"teleporter_main": teleporter_main = value
		"player": player = value
		_: push_warning("IC: Unrecognized global key '%s'" % name)
