extends Node2D
class_name SGCameraBasedAudio
@export var max_distance := 2000.0
@export var pool_size := 16
@export var sound_library :=  {
	"laser_fire": preload("res://assets/sounds/weapons/lasershot_cropped.wav"),
	"rocket_launch": preload("res://assets/sounds/weapons/firework-launch-sound-effect_cropped.wav"),
	"shotgun_fire": preload("res://assets/sounds/shotgun_cropped.wav"),
}
var camera: Camera2D = null
var player_pool: Array[AudioStreamPlayer2D] = []
var next_index := 0

func _ready():
	Utils.sg_audio = self
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_warning("SGCameraBasedAudio: No Camera2D found.")

	for i in pool_size:
		var p = AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.volume_db = -80
		add_child(p)
		player_pool.append(p)

func play_named(name: String, position: Vector2, intensity: float, global := false):
	print("BEGIN TRY TO PLAYED SOUND")
	if not sound_library.has(name):
		push_warning("Sound '%s' not found in library." % name)
		return
	play_sound(sound_library[name], position, intensity, global)
	print("SOUND PLAYED")

func play_sound(stream: AudioStream, position: Vector2, intensity: float, global := false):
	if not is_instance_valid(camera) or not stream:
		return

	var distance := camera.global_position.distance_to(position)
	var volume :float= 1.0 if global else clamp(1.0 - (distance / max_distance), 0.0, 1.0)
	print("dist for volume: ", distance)
	volume *= intensity
	if volume <= 0.01:
		print("insufficient volume")
		return

	var player = player_pool[next_index]
	next_index = (next_index + 1) % pool_size

	player.stop()
	player.global_position = position
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	print("REAL PLAY", volume)
	player.play()

func linear_to_db(vol: float) -> float:
	return clamp(20.0 * log(max(vol, 0.001)) / log(10.0), -80, 0)
