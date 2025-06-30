extends Sprite2D
class_name SpriteFlash

@export var flash_visible_duration := 0.07
@export var parent_fire_signal_name := "fire_signal"
@export var debug_mode_auto_flash := false

var flash_timer := 0.0
var is_flashing := false

func _ready():
	visible = false

	var parent_node := get_parent()
	if parent_node is not Weapon:
		parent_node = parent_node.get_parent()
	if parent_node and parent_node.has_signal(parent_fire_signal_name):
		parent_node.connect(parent_fire_signal_name, Callable(self, "fire_flash"))
	else:
		push_warning("SpriteFlash: Could not connect to signal '%s'" % parent_fire_signal_name)

	z_index = 4

	if debug_mode_auto_flash:
		fire_flash()

func fire_flash():
	is_flashing = true
	flash_timer = 0.0
	visible = true
	set_process(true)

func _process(delta):
	if not is_flashing:
		return

	flash_timer += delta
	if flash_timer >= flash_visible_duration:
		visible = false
		is_flashing = false
		set_process(debug_mode_auto_flash)
