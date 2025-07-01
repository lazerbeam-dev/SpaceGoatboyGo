extends Node

var toggled := false
var drop_toggled := false
var destroy_toggled := false

func _process(_delta):
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Util.try_once_per_frame("debug_click_drop"):
		#var test = preload("res://scenes/creatures/item_drop.tscn").instantiate()
		#test.global_position = get_viewport().get_camera_2d().get_global_mouse_position()
		#get_tree().current_scene.add_child(test)
		#print("drop")
	# L → toggle dissolve
	if Input.is_key_pressed(KEY_L) and not toggled:
		toggled = true
		var model := get_parent()
		if model.has_method("begin_dissolve"):
			print("dissolving")
			if model.is_dissolved:
				model.revert_materials()
			else:
				var rand_color = Color(randf(), randf(), randf()).lightened(0.5)
				model.begin_dissolve()
	if not Input.is_key_pressed(KEY_L):
		toggled = false

	# O → call drop_weapons
	if Input.is_key_pressed(KEY_O) and not drop_toggled:
		drop_toggled = true
		var controller := get_parent()
		if controller.has_method("drop_weapons"):
			print("dropping weapons")
			controller.drop_weapons()
	if not Input.is_key_pressed(KEY_O):
		drop_toggled = false

	# K → call _destroy_self on parent
	if Input.is_key_pressed(KEY_K) and not destroy_toggled:
		destroy_toggled = true
		var parent := get_parent()
		if parent and parent.has_method("_destroy_self"):
			print("triggering parent _destroy_self()")
			parent._destroy_self()
	if not Input.is_key_pressed(KEY_K):
		destroy_toggled = false
