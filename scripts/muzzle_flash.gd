extends Sprite2D

@export var min_radius := 0.01        # Where the flash starts
@export var peak_radius := 0.3        # The big burst
@export var settle_radius := 0.05     # Final radius before invisibility
@export var grow_duration := 0.02     # Time to reach peak
@export var shrink_duration := 0.03   # Time to fall to settle
@export var parent_fire_signal_name := "fire_signal"
@export var debug_mode_auto_flash := false

var flash_timer := 0.0
var is_flashing := false

func _ready():
	# Ensure material is unique and is a ShaderMaterial
	var mat := material
	if mat and mat is ShaderMaterial:
		material = mat.duplicate()
	else:
		push_error("MuzzleFlash: Material must be a ShaderMaterial.")
		visible = false
		set_process(false)
		return

	visible = false

	var parent_node := get_parent()
	if parent_node is not Weapon:
		parent_node = parent_node.get_parent()
	if parent_node and parent_node.has_signal(parent_fire_signal_name):
		parent_node.connect(parent_fire_signal_name, Callable(self, "fire_flash"))
	else:
		push_warning("MuzzleFlash: Could not connect to parent signal '%s'" % parent_fire_signal_name)
	z_index = 4
	if debug_mode_auto_flash:
		fire_flash()

func fire_flash():
	print(get_parent().name, "fired flash")
	is_flashing = true
	visible = true
	flash_timer = 0.0
	_set_radius(min_radius)
	set_process(true)

func _process(delta):
	if not is_flashing:
		return

	flash_timer += delta
	var total_duration := grow_duration + shrink_duration

	if flash_timer < grow_duration:
		var t := flash_timer / grow_duration
		_set_radius(lerp(min_radius, peak_radius, t))
	elif flash_timer < total_duration:
		var t := (flash_timer - grow_duration) / shrink_duration
		_set_radius(lerp(peak_radius, settle_radius, t))
	else:
		visible = false
		is_flashing = false
		set_process(debug_mode_auto_flash)

func _set_radius(value: float):
	var mat := material
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("max_radius", value)
