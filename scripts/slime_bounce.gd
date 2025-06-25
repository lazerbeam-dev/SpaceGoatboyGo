extends CharacterBody2D
class_name SlimeBounce

@export var planet_path: NodePath

# === BOUNCE TUNING ===
@export var gravity_strength: float = 980.0
@export var jump_velocity: float = -400.0
@export var bounciness: float = 0.9
@export var initial_push: float = 220.0
@export var max_tangent_speed: float = 420.0
@export var tangent_accel: float = 120.0

var planet: Node2D
var facing_right := true
var has_launched := false
var preferred_tangent_sign := 1.0

func _ready():
	planet = get_tree().current_scene.get_node_or_null("Planet")
	if not planet:
		push_error("SlimeBounce: Planet not found at Game/Planet")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(planet):
		return

	var gravity_dir: Vector2 = (planet.global_position - global_position).normalized()
	var up_dir: Vector2 = -gravity_dir
	up_direction = up_dir
	var right_dir: Vector2 = Vector2(-up_dir.y, up_dir.x)

	velocity += gravity_dir * gravity_strength * delta

	if not has_launched:
		velocity += right_dir * initial_push
		preferred_tangent_sign = sign(initial_push)
		has_launched = true

	var collision = move_and_collide(velocity * delta)

	if collision != null:
		var normal = collision.get_normal()
		velocity = velocity.bounce(normal) * bounciness

		if normal.dot(up_dir) > 0.8:
			velocity += up_dir * abs(jump_velocity)

	var tangent_speed := velocity.dot(right_dir)
	if sign(tangent_speed) != 0 and sign(tangent_speed) != preferred_tangent_sign:
		preferred_tangent_sign = sign(tangent_speed)

	var desired_speed := tangent_speed + tangent_accel * delta * preferred_tangent_sign
	desired_speed = clamp(desired_speed, -max_tangent_speed, max_tangent_speed)
	velocity = right_dir * desired_speed + up_dir * velocity.dot(up_dir)

	rotation = up_dir.angle() + (PI / 2 if facing_right else -PI / 2)
