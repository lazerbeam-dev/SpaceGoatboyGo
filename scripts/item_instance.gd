class_name ItemInstance
extends Resource

@export var scene_path: String  # e.g. "res://items/weapons/laser_blaster.tscn"
@export var tags: Array[String] = []  # e.g. ["weapon", "laser", "two_handed"]
@export var durability: float = 1.0  # (0.0–1.0 scale or whatever)
