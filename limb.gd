### limb.gd
extends Node
class_name Limb

@export var abilities: Array[String] = []
@export var strength: float = 50.0
@export var limb_type: String = "arm" # e.g. "legs", "arm", "head"
var status: String = "free"  # "walking", "attacking", etc.

func get_abilities() -> Array[String]:
	var all_abilities: Array[String] = abilities.duplicate()
	for child in get_children():
		if child is Limb:
			var child_abilities = child.get_abilities()
			for ability in child_abilities:
				if not all_abilities.has(ability):
					all_abilities.append(ability)
	return all_abilities

func get_strength() -> float:
	return strength

func get_limb_type() -> String:
	return limb_type

func is_occupied() -> bool:
	return status != "free"
