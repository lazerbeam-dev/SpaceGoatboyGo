extends Area2D

@export var cooldown_duration := 3.0
@export var pull_interval := 0.2
@export var pull_strength := 800.0
@export var snap_threshold := 2.0
@export var wall_collision_mask := 1
@export var max_engulf_radius := -1.0  # If negative, auto-set from self

var _last_absorbed_time := {}
var _absorbed_bodies: Array[Node2D] = []
var _body_cores := {}
var _core_velocities := {}
var _self_radius := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	_self_radius = get_body_radius(self)
	set_process(true)

func _on_body_entered(body: Node):
	var body_radius = get_body_radius(body)
	print(body, body.owner, body_radius, "body owner, slime", max_engulf_radius)

	if body_radius > max_engulf_radius:
		# Too big — bounce off!
		if owner is SlimeBounce and owner.has_method("velocity"):
			
			var slime: SlimeBounce = owner
			var dir :Vector2= (slime.global_position - body.global_position).normalized()
			
			# Simulate a bounce
			var normal := dir
			slime.velocity = -slime.velocity
			
			## Optional: Add a little vertical impulse if we're hitting the ground
			#var up_dir = -(slime.planet.global_position - slime.global_position).normalized()
			#if normal.dot(up_dir) > 0.7:
				#slime.velocity += up_dir * abs(slime.jump_velocity)

		return

	if not has_clear_path_for_body(global_position, body.global_position, body_radius):
		return

	var now := Time.get_unix_time_from_system()
	if _last_absorbed_time.has(body) and now - _last_absorbed_time[body] < cooldown_duration:
		return

	_last_absorbed_time[body] = now
	call_deferred("_reparent_and_absorb", body)


func _process(delta):
	for body in _absorbed_bodies.duplicate():
		if not is_instance_valid(body):
			_cleanup_body(body)
			continue

		if not overlaps_body(body):
			_unabsorb(body)
			continue

		var core = _body_cores.get(body)
		if not core or not is_instance_valid(core):
			continue

		var prev_pos :Vector2= core.position

		# Use victim input to move their core
		if body.has_method("get_move_input"):
			var dir = clampf(body.get_move_input(), -1.0, 1.0)
			core.position.x += dir * 40.0 * delta  # adjust speed here

		# Pull core back to center
		var to_center = to_local(global_position) - core.position
		core.position += to_center.normalized() * pull_strength * pull_interval * delta
		if to_center.length() < snap_threshold:
			core.position = to_local(global_position)

		# Snap body to core
		body.global_position = core.global_position

		# Track core velocity
		var vel :Vector2= (core.position - prev_pos) / delta
		_core_velocities[body] = vel

func _unabsorb(body: Node2D):
	if not is_instance_valid(body):
		return

	var core = _body_cores.get(body)
	if core and is_instance_valid(core):
		if body.get_parent() == core:
			var global_pos := body.global_position
			core.remove_child(body)
			get_tree().current_scene.add_child(body)

			# Find a safe ejection position with stricter checking
			var safe_pos := find_safe_ejection_position(body, global_pos)
			if safe_pos != Vector2.INF:
				body.global_position = safe_pos
			else:
				print("Blocked! Keeping body absorbed for now")
				# Re-absorb the body since we couldn't find a safe spot
				get_tree().current_scene.remove_child(body)
				core.add_child(body)
				body.global_position = core.global_position
				return  # Don't unabsorb yet

			# Apply inherited core velocity plus ejection burst
			if body is CharacterBody2D:
				var core_vel :Vector2 = _core_velocities.get(body, Vector2.ZERO)
				var eject_dir := (body.global_position - global_position).normalized()
				body.velocity = core_vel + eject_dir * 500.0  # Squirt boost

	_set_external_control(body, false)
	_last_absorbed_time[body] = Time.get_unix_time_from_system()  # Start cooldown now
	_cleanup_body(body)

func find_safe_ejection_position(body: Node2D, preferred_pos: Vector2) -> Vector2:
	var body_radius := get_body_radius(body)
	
	# First, try the preferred position with strict checking
	if is_position_completely_safe(preferred_pos, body_radius, body):
		return preferred_pos
	
	# Get the preferred direction (from absorber center to preferred position)
	var preferred_dir := (preferred_pos - global_position).normalized()
	var base_distance :float= max(64.0, body_radius * 3.0)  # Increased minimum distance
	
	# Try only a few positions in the preferred direction - be much more conservative
	for distance_multiplier in [1.0, 1.5, 2.0]:
		var test_distance :float= base_distance * distance_multiplier
		var test_pos := global_position + preferred_dir * test_distance
		
		if is_position_completely_safe(test_pos, body_radius, body):
			return test_pos
	
	# Try only immediately adjacent angles (±45°) - much more restrictive
	var nearby_angles := [PI/4, -PI/4]  # Only 45° either side
	
	for distance_multiplier in [1.0, 1.5]:
		var test_distance :float= base_distance * distance_multiplier
		
		for angle_offset in nearby_angles:
			var test_dir := preferred_dir.rotated(angle_offset)
			var test_pos := global_position + test_dir * test_distance
			
			if is_position_completely_safe(test_pos, body_radius, body):
				return test_pos
	
	return Vector2.INF  # No safe position found - be strict!

func get_body_radius(body: Node2D) -> float:
	var bodyForInspection :Node2D= null
	if body is Creature:
		return body.size
	
	var owner := body.owner
	if owner and owner is Creature:
		return owner.sizea
	return 16.0  # Fallback radius if not a Creature or no owner


func is_position_completely_safe(pos: Vector2, body_radius: float, _body: Node2D) -> bool:
	# First, check if there's a clear path from absorber to the ejection position
	if not has_clear_path_for_body(global_position, pos, body_radius):
		return false
	
	# Then check if the final position itself is safe
	var expanded_radius = body_radius * 1.2  # Add some safety margin
	
	# Check multiple points around the body's collision area with expanded radius
	var test_points = [
		pos,  # Center
		pos + Vector2(expanded_radius, 0),      # Right
		pos + Vector2(-expanded_radius, 0),     # Left  
		pos + Vector2(0, expanded_radius),      # Down
		pos + Vector2(0, -expanded_radius),     # Up
		pos + Vector2(expanded_radius * 0.7, expanded_radius * 0.7),    # Diagonal corners
		pos + Vector2(-expanded_radius * 0.7, expanded_radius * 0.7),
		pos + Vector2(expanded_radius * 0.7, -expanded_radius * 0.7),
		pos + Vector2(-expanded_radius * 0.7, -expanded_radius * 0.7)
	]
	
	var params := PhysicsPointQueryParameters2D.new()
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = wall_collision_mask
	# Only exclude the absorber itself, not the body being ejected
	params.exclude = [self]

	var space_state := get_world_2d().direct_space_state
	
	for test_point in test_points:
		params.position = test_point
		var result := space_state.intersect_point(params)
		if not result.is_empty():
			return false  # Found collision at this point
	
	return true

func has_clear_path_for_body(from: Vector2, to: Vector2, body_radius: float) -> bool:
	# Check multiple parallel rays to account for body width
	var direction := (to - from).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	
	# Check center ray and rays offset by body radius
	var rays_to_check = [
		{"from": from, "to": to},  # Center ray
		{"from": from + perpendicular * body_radius * 0.8, "to": to + perpendicular * body_radius * 0.8},  # Left edge
		{"from": from - perpendicular * body_radius * 0.8, "to": to - perpendicular * body_radius * 0.8},  # Right edge
	]
	
	var params := PhysicsRayQueryParameters2D.new()
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = wall_collision_mask
	params.exclude = [self]  # Only exclude the absorber
	
	var space_state := get_world_2d().direct_space_state
	
	for ray in rays_to_check:
		params.from = ray.from
		params.to = ray.to
		var result := space_state.intersect_ray(params)
		if not result.is_empty():
			return false  # Path is blocked
	
	return true

func _reparent_and_absorb(body: Node2D):
	if not is_instance_valid(body):
		return

	# Create new absorber core
	var core := Node2D.new()
	core.name = "%s_AbsorbCore" % body.name
	core.position = to_local(global_position)
	add_child(core)

	if body.get_parent():
		body.get_parent().remove_child(body)
	var original_rotation := body.global_rotation
	core.add_child(body)
	body.global_position = core.global_position
	body.global_rotation = original_rotation

	_set_external_control(body, true)
	_absorbed_bodies.append(body)
	_body_cores[body] = core

func _set_external_control(body: Node, state: bool):
	if body.has_method("set_ext"):
		body.set_ext(state)

func _cleanup_body(body):
	if not is_instance_valid(body):
		return
	if not (body is Node2D):
		return

	_absorbed_bodies.erase(body)

	if _body_cores.has(body):
		var core = _body_cores[body]
		if is_instance_valid(core) and core.get_parent():
			core.queue_free()
		_body_cores.erase(body)

	_core_velocities.erase(body)
