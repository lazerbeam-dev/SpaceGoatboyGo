class_name Inventory
extends Node

enum InventoryType {
	MAIN,
	ARMS,
	BELT,
	TORSO,
	LEGS,
	SHOES,
	BACKPACK,
	HEAD
}

@export var inventory_type: InventoryType
@export var slots: Array[InventorySlot] = []

func get_first() -> PackedScene:
	for slot in slots:
		if slot.item_scene:
			return slot.item_scene
	return null

func get_all() -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	for slot in slots:
		if slot.item_scene:
			result.append(slot.item_scene)
	return result

func add_item(item: PackedScene) -> bool:
	for slot in slots:
		if slot.item_scene == null:
			slot.item_scene = item
			return true
	return false
	
