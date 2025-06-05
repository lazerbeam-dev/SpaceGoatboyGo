extends Node2D
class_name Weapon

@export var cooldown := 0.5
@export var projectile_scene: PackedScene
@export var muzzle_offset := Vector2(20, 0)

var _last_fired_time := 0.0

func attempt_fire(direction: Vector2, global_time: float) -> void:
	if global_time - _last_fired_time < cooldown:
		return
	_last_fired_time = global_time
	print("attmpetfire")
	fire(direction)

func fire(_direction: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	# Calculate muzzle position and direction in global space
	var muzzle_pos = global_transform.origin + global_transform.x * muzzle_offset.x + global_transform.y * muzzle_offset.y
	var muzzle_dir = global_transform.x.normalized()

	projectile.global_position = muzzle_pos
	projectile.rotation = muzzle_dir.angle()
	
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(muzzle_dir * projectile.speed)

	print("Firing projectile from %s toward angle %f" % [str(muzzle_pos), muzzle_dir.angle()])

	
	# Add your own velocity logic, etc.
