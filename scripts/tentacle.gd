extends Line2D
class_name TentaclePath

@export var origin: Node2D
@export var destination: Node2D
@export var segment_count: int = 12
@export var base_amplitude: float = 80.0
@export var wave_speed: float = 5.0
@export var amplitude_falloff := true  # Optional toggle to fall off based on distance

var _phase := 0.0

func _ready():
	set_process(true)
	_update_points()

func _process(delta):
	if not is_instance_valid(origin) or not is_instance_valid(destination):
		#print("inv", is_instance_valid(origin), is_instance_valid(destination))
		return
	_phase += delta * wave_speed
	_update_points()

func _update_points():
	if not is_instance_valid(origin) or not is_instance_valid(destination):
		points = PackedVector2Array()
		return

	var start = origin.global_position
	var end = destination.global_position
	var base_vector = end - start
	var distance = base_vector.length()
	var direction = base_vector.normalized()
	var perpendicular = direction.rotated(PI / 2)

	var effective_amplitude = base_amplitude
	if amplitude_falloff and distance > 0:
		effective_amplitude = base_amplitude * (300.0 / distance)  # Tune `300.0` to taste
		effective_amplitude = clamp(effective_amplitude, 4.0, base_amplitude)  # Prevent collapse

	var new_points := PackedVector2Array()
	for i in range(segment_count + 1):
		var t = float(i) / segment_count
		var base_point = start.lerp(end, t)

		var wave = sin(t * PI * 2 + _phase) * effective_amplitude * sin(PI * t)
		var offset = perpendicular * wave
		new_points.append(to_local(base_point + offset))

	points = new_points
	queue_redraw()
