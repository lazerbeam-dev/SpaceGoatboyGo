extends Control
class_name HUDMain

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var mission_label: RichTextLabel = $MissionLabel
@onready var money_label: RichTextLabel = $Money/AmountText

@onready var arm_slots: HBoxContainer = $ArmSlots
@onready var debug_label: RichTextLabel = $I/ScrollContainer/VBoxContainer/LogOutput
@onready var debug_scroll: ScrollContainer = $I/ScrollContainer
@onready var info_control: Control = $I/ScrollContainer  # Reference to the full info panel
@export var log_output_scene: PackedScene = preload("res://scenes/government/log_output.tscn")
@onready var debug_log_container: VBoxContainer = $I/ScrollContainer/VBoxContainer
const MAX_DEBUG_LINES := 200
var debug_log_lines: Array[String] = []
var default_hand_icon: Texture = preload("res://assets/sprites/cursors/hoof_cursor.png")

func _ready():
	Utils.hud = self
	
	debug_label.clear()
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.bbcode_enabled = false
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	debug_label.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	debug_label.custom_minimum_size = Vector2(300, 100)
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.add_theme_color_override("font_color", Color(1, 1, 1))

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.set_content_margin_all(8)
	debug_label.add_theme_stylebox_override("normal", bg)

	for i in range(arm_slots.get_child_count()):
		var button = arm_slots.get_child(i)
		if button is TextureButton:
			button.connect("pressed", Callable(self, "_on_arm_slot_pressed").bind(i))

func toggle_information() -> void:
	info_control.visible = not info_control.visible

func update_hp_ratio(ratio: float) -> void:
	hp_bar.value = clamp(ratio, 0.0, 1.0) * 100.0

func show_mission(text: String) -> void:
	mission_label.text = text
func display_money(text: String) -> void:
	money_label.text = text
	
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

func debug_log(msg: String) -> void:
	var log_label := log_output_scene.instantiate() as RichTextLabel
	log_label.text = msg
	debug_log_container.add_child(log_label)

	if debug_log_container.get_child_count() > MAX_DEBUG_LINES:
		debug_log_container.get_child(0).queue_free()

	await get_tree().process_frame
	debug_scroll.scroll_vertical = debug_scroll.get_v_scroll_bar().max_value
