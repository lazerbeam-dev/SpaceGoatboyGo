extends Control
class_name HUDMain

func _ready():
	Utils.hud = self

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var mission_label: RichTextLabel = $MissionLabel

func update_hp_ratio(ratio: float) -> void:
	hp_bar.value = clamp(ratio, 0.0, 1.0) * 100.0  # assuming HPBar.max_value = 100

func show_mission(text: String) -> void:
	mission_label.text = text
