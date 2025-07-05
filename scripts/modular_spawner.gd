extends Node2D
class_name ModularSpawner

@export var object_to_spawn: PackedScene
@export var reference_orientation: NodePath
@export var velocity: Vector2 = Vector2.ZERO
@export var z_index_on_spawn := 0
@export_range(0.0, 99999.0) var max_distance_from_camera := 2000.0
@export var spawn_interval := 2.0  # Seconds between spawns, 0 = one-time only

var _spawn_timer := 0.0
var orientation_source: Node2D = null

func _ready():
	orientation_source = get_node_or_null(reference_orientation)
	call_deferred("_try_spawn")

func _try_spawn():
	if not object_to_spawn:
		push_warning("No object assigned to spawn.")
		return

	var camera := Utils.get_current_camera()
	if camera:
		var dist := camera.global_position.distance_to(self.global_position)
		if dist > max_distance_from_camera:
			print("Too far from camera (%.1f units). Skipping spawn and opting for simulation instead." % dist)
			return

	var instance = object_to_spawn.instantiate()

	if instance is Node2D:
		instance.global_position = self.global_position
		instance.z_index = z_index_on_spawn

		var reference_rot := orientation_source.global_rotation if orientation_source else self.global_rotation
		var applied_velocity := velocity.rotated(reference_rot)

		if instance is CharacterBody2D:
			instance.velocity = applied_velocity
	else:
		push_warning("Spawned object is not a Node2D; cannot set position/z_index.")

	self.get_tree().current_scene.add_child(instance, true)

func _process(delta):
	if spawn_interval <= 0.0:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn()
