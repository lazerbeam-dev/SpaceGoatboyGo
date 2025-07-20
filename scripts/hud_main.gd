extends Control
class_name HUDMain

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var mission_label: RichTextLabel = $MissionLabel
@onready var arm_slots: HBoxContainer = $ArmSlots
const MAX_DEBUG_LINES := 200
var debug_log_lines: Array[String] = []

@onready var debug_label: RichTextLabel = $ScrollContainer/LogOutput
@onready var debug_scroll: ScrollContainer = $ScrollContainer
var default_hand_icon: Texture = preload("res://assets/sprites/cursors/hoof_cursor.png")

func _ready():
	Utils.hud = self
	
	# Set debug log styling
	debug_label.clear()
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.bbcode_enabled = false  # Set true if you want markup later
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	debug_label.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	debug_label.custom_minimum_size = Vector2(300, 100)
	# Create a font if needed
	var default_font := FontFile.new()
	#default_font.load("res://default_font.tres")  # Or skip this if already set in project
	#debug_label.add_theme_font_override("font", default_font)
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.add_theme_color_override("font_color", Color(1, 1, 1))  # white

	# Optional: background
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.set_content_margin_all(8)
	debug_label.add_theme_stylebox_override("normal", bg)

	# Set up arm button signals
	for i in range(arm_slots.get_child_count()):
		var button = arm_slots.get_child(i)
		if button is TextureButton:
			button.connect("pressed", Callable(self, "_on_arm_slot_pressed").bind(i))

func update_hp_ratio(ratio: float) -> void:
	hp_bar.value = clamp(ratio, 0.0, 1.0) * 100.0

func show_mission(text: String) -> void:
	mission_label.text = text

func update_weapon_icons(icon_textures: Array[Texture]) -> void:
	for i in range(arm_slots.get_child_count()):
		var slot = arm_slots.get_child(i)
		if not slot is TextureButton:
			continue

		var texture: Texture = default_hand_icon
		if i < icon_textures.size() and icon_textures[i] != null:
			texture = icon_textures[i]
		slot.texture_normal = texture
func _on_arm_slot_pressed(index: int) -> void:
	print("Clicked arm slot:", index)
	# TODO: Open inventory, cycle weapons, highlight, etc.
	
func debug_log(msg: String) -> void:
	debug_log_lines.append(msg)
	if debug_log_lines.size() > MAX_DEBUG_LINES:
		debug_log_lines.pop_front()

	debug_label.text = "\n".join(debug_log_lines)
	await get_tree().process_frame  # Ensure scroll height is updated
	debug_scroll.scroll_vertical = debug_scroll.get_v_scroll_bar().max_value
