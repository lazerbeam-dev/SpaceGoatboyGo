extends Area2D
class_name PlanetCoreTeleporter

@export var planet_path: NodePath
@export var teleport_radius: float = 1000.0
@export var safe_check_distance: float = 48.0
@export var safety_attempts: int = 10

var planet: Node2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	planet = get_node_or_null(planet_path)
	if not planet:
		push_error("PlanetCoreTeleporter: No planet found at path: %s" % planet_path)

func _on_body_entered(body: Node2D) -> void:
	if not planet:
		return

	var collision_layer :int= body.get_collision_layer()
	if (collision_layer & (1 << 1)) == 0 and (collision_layer & (1 << 2)) == 0:
		return  # Not on layer 2 or 3

	for i in range(safety_attempts):
		var angle = randf() * TAU
		var target_pos = planet.global_position + Vector2(cos(angle), sin(angle)) * teleport_radius

		if is_position_safe(target_pos, body):
			body.global_position = target_pos
			if body.has_method("reset_velocity"):
				body.reset_velocity()  # optional support
			return

	push_error("PlanetCoreTeleporter: Failed to find safe teleport location after %d attempts for body %s" % [safety_attempts, body.name])

func is_position_safe(pos: Vector2, body: Node2D) -> bool:
	var space_state = get_world_2d().direct_space_state

	var shape := RectangleShape2D.new()
	var extents = safe_check_distance * Vector2.ONE
	shape.extents = extents

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = body.get_collision_mask()  # check against what this body collides with
	query.exclude = [body]

	var result = space_state.intersect_shape(query, 1)
	return result.is_empty()
