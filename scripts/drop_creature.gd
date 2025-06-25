extends CharacterBody2D
class_name DroppedCreature

@export var planet_path: NodePath
@export var gravity_strength := 980.0
@export var stop_speed_threshold := 50.0  # Speed below which the item stops completely

var planet: Node2D
var gravity_dir := Vector2.DOWN

func _ready():
	planet = get_node_or_null(planet_path)
	if not planet:
		var current = self
		while current:
			if current.name == "Game":
				planet = current.get_node_or_null("Planet")
				break
			current = current.get_parent()
	
	if not planet:
		push_error("DroppedCreature: No planet found.")

func _physics_process(delta):
	if not planet:
		return
	
	# Calculate gravity direction toward planet center
	gravity_dir = (planet.global_position - global_position).normalized()
	var up_dir = -gravity_dir
	up_direction = up_dir
	
	# Apply gravity
	velocity += gravity_dir * gravity_strength * delta
	
	# Slide and slow on ground
	if is_on_floor() and velocity.dot(up_dir) <= 0:
		var floor_normal = get_floor_normal()
		var slope_steepness = floor_normal.dot(up_dir)  # 1.0 = flat, 0.0 = vertical
		
		# On very shallow slopes, stop sliding completely
		if slope_steepness > 0.85:  # ~32 degrees or shallower
			# Remove all tangential movement, keep only normal forces
			var normal_velocity = velocity.dot(floor_normal) * floor_normal
			if normal_velocity.dot(floor_normal) < 0:  # Only if pushing into surface
				velocity = normal_velocity
			else:
				velocity = Vector2.ZERO
		else:
			var tangent = Vector2(-up_dir.y, up_dir.x)
			var tangent_speed = velocity.dot(tangent)
			
			# On very steep slopes, apply minimal friction
			if slope_steepness < 0.3:  # ~73 degrees or steeper - almost no friction
				tangent_speed = move_toward(tangent_speed, 0.0, 50.0 * delta)  # Tiny friction
				# Almost no stop threshold - let it rip!
				if abs(tangent_speed) < 5.0:
					tangent_speed = 0.0
			else:
				# Normal friction scaling for medium slopes
				var base_friction = 1600.0
				var steepness_factor = 1.0 - slope_steepness
				var friction_reduction = steepness_factor * steepness_factor
				base_friction *= (1.0 - friction_reduction * 0.7)
				
				tangent_speed = move_toward(tangent_speed, 0.0, base_friction * delta)
				
				var adaptive_threshold = stop_speed_threshold * (0.2 + slope_steepness * 0.8)
				if abs(tangent_speed) < adaptive_threshold:
					tangent_speed = 0.0
			
			velocity = tangent * tangent_speed + up_dir * velocity.dot(up_dir)
	
	move_and_slide()
