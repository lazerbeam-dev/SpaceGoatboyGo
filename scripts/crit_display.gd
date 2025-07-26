extends Node2D
class_name CritDrawOverlay

@export var flash_sprite_path: NodePath
@export var draw_time := 0.2  # Seconds to stay visible
@export var flash_color := Color(1, 0, 0, 0.3)  # Red translucent

var flash_sprite: Sprite2D
var timer := 0.0

func _ready():
	flash_sprite = get_node_or_null(flash_sprite_path)
	if flash_sprite:
		flash_sprite.visible = false
		flash_sprite.modulate = flash_color
	else:
		push_warning("CritDrawOverlay: No flash sprite assigned.")

func _process(delta: float) -> void:
	if timer > 0.0:
		timer -= delta
		if timer <= 0.0 and flash_sprite:
			flash_sprite.visible = false

func show_flash():
	if not flash_sprite:
		return
	print("flash!")
	flash_sprite.visible = true
	timer = draw_time
