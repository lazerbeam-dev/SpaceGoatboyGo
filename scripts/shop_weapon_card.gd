extends HBoxContainer
class_name WeaponCard

@onready var name_label: Label = $VBox/Name
@onready var cost_label: Label = $VBox/Cost

var weapon_scene: PackedScene
var cost: int = 0

func setup(weapon: PackedScene, name: String, cost_val: int) -> void:
	weapon_scene = weapon
	name_label.text = name
	cost = cost_val
	cost_label.text = "Cost: %d GBX" % cost
