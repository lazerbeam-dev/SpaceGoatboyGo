extends Node2D
class_name Weapon
signal fire_signal # Changed to 'fire_signal' 
@export var cooldown := 0.5
@export var projectile_scene: PackedScene
var muzzle_offset : Vector2
# Preload the item drop wrapper scene
var dropped_item_scene := preload("res://scenes/creatures/item_drop.tscn")
@export var dropped_radius := 3.0  # Size of the pickup circle
@export var allow_drop := true  # Some weapons might be spiritual or bound
@export var effective_z_index := 1
var _last_fired_time := 0.0
var owner_body: Node2D = null

@onready var barrel := $Barrel


func _ready():
	owner_body = find_owner_body()
	if not owner_body:
		print("Weapon could not find a CreatureController in its parent hierarchy")

	# Auto-equip on spawn if grandparent is CreatureWeaponController
	var grandparent := get_parent().get_parent()
	if grandparent and grandparent is CreatureWeaponController:
		var arm = get_parent()
		if arm is Arm:
			grandparent.switch_weapon_for_arm(arm, self)

func attempt_fire(direction: Vector2, global_time: float) -> void:
	if global_time - _last_fired_time < cooldown:
		return
	_last_fired_time = global_time
	emit_signal("fire_signal") 
	fire(direction)


func fire(_direction: Vector2) -> void:
	var barrel_dir = barrel.global_transform.x.normalized()
	
	spawn_projectile(barrel_dir)
	
func on_equip():
	var total_z := z_index
	var node := get_parent()
	while node:
		if node is CanvasItem:
			total_z += node.z_index
		node = node.get_parent()
	effective_z_index = total_z


func find_owner_body() -> Node2D:
	var node := get_parent()
	while node:
		if "set_move_input" in node:
			return node as Node2D  # Likely a CreatureController-like object
		node = node.get_parent()
	return null
	
func drop_self():
	if not allow_drop:
		print("ndrop")
		return
	if not is_inside_tree():
		return
	
	var scene_root := get_tree().current_scene
	if not scene_root:
		return;
	if not dropped_item_scene:
		push_error("No dropped_item_scene assigned.")
		return




	# Cache transform before detaching
	var global_pos := global_position
	var global_rot := global_rotation

	# Detach self
	get_parent().remove_child(self)

	# Instance wrapper from scene
	var wrapper := dropped_item_scene.instantiate()
	wrapper.name = "Dropped_%s" % name
	wrapper.global_position = global_pos
	wrapper.global_rotation = global_rot

	# Reset local transform inside wrapper
	self.position = Vector2.ZERO
	self.rotation = 0
	wrapper.add_child(self)

	# Add to scene
	scene_root.add_child(wrapper)
	
func spawn_projectile(direction: Vector2) -> void:
	if not projectile_scene or not is_instance_valid(barrel):
		push_warning("Missing projectile scene or barrel")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = barrel.global_position
	projectile.rotation = direction.angle()

	# Apply velocity
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction.normalized() * projectile.speed, owner_body)
	elif "velocity" in projectile:
		projectile.velocity = direction.normalized() * projectile.speed


	for child in projectile.get_children():
		if child is Sprite2D:
			child.z_index = effective_z_index +1
			break
