extends SGEntity
class_name HooverSeeker

@export var speed: float = 180.0
@export var acceleration: float = 600.0
@export var drag: float = 0.8

var is_passive := false  # Set true when reparented / attached

func _physics_process(delta):
	if is_passive:
		velocity = Vector2.ZERO
		return

	if move_input.length() > 0.01:
		var target_velocity = move_input.normalized() * speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

	move_and_slide()
