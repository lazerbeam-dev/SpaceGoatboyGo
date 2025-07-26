extends Node2D
class_name GovernmentParticles



@export var effects: Dictionary = {
	"mission_complete": preload("res://scenes/government/confetti_burst.tscn"),
	"level_up": preload("res://scenes/government/level_up_burst.tscn"),
}
@export var lifetime := 1.2  # How long each effect lasts
@export var default_position := Vector2.ZERO  # Usually center of screen

func _ready():
	Utils.gov_particles = self

func play_effect(effect_type: String, position := default_position):
	print("PLAY EFFECT", effect_type)
	if not effects.has(effect_type):
		push_warning("No effect defined for type: " + effect_type)
		return

	var particle_scene: PackedScene = effects[effect_type]
	var instance = particle_scene.instantiate()
	add_child(instance)
	instance.global_position = position

	if instance is GPUParticles2D:
		print("VALID PARTICLES")
		instance.restart()

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(instance):
		instance.queue_free()
