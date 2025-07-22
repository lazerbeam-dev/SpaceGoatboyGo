extends Node2D
class_name GovernmentParticles

@export var particle_scene: PackedScene = preload("res://scenes/government/gold_spark.tscn")
@export var lifetime := 0.7 # seconds to keep the particle effect alive

func spawn_explosion(pos: Vector2):
	var explosion = particle_scene.instantiate()
	add_child(explosion)
	explosion.global_position = pos

	var particles := explosion.get_node_or_null("Particles")
	if particles and particles is GPUParticles2D:
		particles.restart()

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()
