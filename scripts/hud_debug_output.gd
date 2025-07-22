extends Control

@onready var debug_label: RichTextLabel = $"ScrollContainer/VBoxContainer/LogOutput"
@onready var scroll_container: ScrollContainer = $"ScrollContainer"
@onready var i_container: Control = $"ScrollContainer"
const MAX_LINES := 200
var log_lines: Array[String] = []
var visi = false
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it catches input
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#debug_label.clip_text = false
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Utils.hud.toggle_information()
func log_debug(message: String) -> void:
	pass
	#log_lines.append(message)
	#if log_lines.size() > MAX_LINES:
		#log_lines.pop_front()
	#debug_label.text = "\n".join(log_lines)
	#await get_tree().process_frame  # Wait a frame to ensure scroll works
	#scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
