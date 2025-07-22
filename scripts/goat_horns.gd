extends Area2D
class_name GoatHorns

@export var push_force_multiplier := 1.0  # How much force to apply based on charging speed
@export var charging_goat_path: NodePath = "../../../.."  # Path to the goat doing the charging
@export var hit_cooldown_seconds := 0.5  # Prevent spam hitting same target
@export var minimum_charge_speed := 0.1  # Must be moving this fast to push
@export var stun_duration := 0.8  # How long to stun hit creatures

var charging_goat: Creature
var recently_hit_targets := {}  # Target -> time_remaining_seconds

func _ready():
	charging_goat = get_node_or_null(charging_goat_path)
	if not charging_goat:
		push_error("GoatHorns: Cannot find charging goat at path: %s" % charging_goat_path)
		return
	
	# Connect the collision signal
	body_entered.connect(_on_target_hit)
	print("GoatHorns: Ready! Goat found: ", charging_goat.name)

func _process(delta: float) -> void:
	# Update cooldown timers for recently hit targets
	var targets_to_remove := []
	
	for hit_target in recently_hit_targets.keys():
		recently_hit_targets[hit_target] -= delta
		if recently_hit_targets[hit_target] <= 0.0:
			targets_to_remove.append(hit_target)
	
	# Clean up expired cooldowns
	for target in targets_to_remove:
		recently_hit_targets.erase(target)

func _on_target_hit(collision_body: Node2D) -> void:
	print("GoatHorns: Something entered collision area: ", collision_body.name)
	
	# Safety checks
	if not charging_goat:
		print("GoatHorns: No charging goat reference!")
		return
	
	var goat_charge_speed := charging_goat.velocity.length()
	if goat_charge_speed <= minimum_charge_speed:
		print("GoatHorns: Goat not moving fast enough (", goat_charge_speed, ")")
		return
	
	# Don't hit yourself
	if collision_body == charging_goat:
		print("GoatHorns: Ignoring self-collision")
		return
	
	# Find the target creature (might be a child node of the collision body)
	var target_creature := find_creature_in_hierarchy(collision_body)
	if not target_creature:
		print("GoatHorns: No creature found in collision body hierarchy")
		return
	
	# Check cooldown to prevent spam
	if recently_hit_targets.has(target_creature):
		print("GoatHorns: Target ", target_creature.name, " still on cooldown")
		return
	
	# Apply stunlock first - this stops the creature's movement input
	target_creature.apply_stun(stun_duration)
	
	# Calculate push direction and force
	var push_success := apply_push_force(target_creature, goat_charge_speed)
	
	if push_success:
		# Add to cooldown list
		recently_hit_targets[target_creature] = hit_cooldown_seconds
		print("GoatHorns: Successfully pushed and stunned ", target_creature.name, " for ", stun_duration, "s")
	else:
		print("GoatHorns: Failed to push ", target_creature.name, " but still applied stun")

func find_creature_in_hierarchy(starting_node: Node) -> Creature:
	# Check if the node itself is a creature
	if starting_node is Creature:
		return starting_node as Creature
	
	# Walk up the parent hierarchy looking for a Creature
	var current_node := starting_node
	while current_node:
		if current_node is Creature:
			return current_node as Creature
		current_node = current_node.get_parent()
	
	return null

func apply_push_force(target_creature: Creature, goat_charge_speed: float) -> bool:
	var goat_velocity_dir := charging_goat.velocity.normalized()
	var goat_forward_dir := Vector2.RIGHT.rotated(charging_goat.rotation)
	
	# Blend: mostly velocity, slightly forward
	var final_push_dir := (goat_velocity_dir * 0.8 + goat_forward_dir * 0.2).normalized()
	
	# Fallback if goat_vel was tiny
	if final_push_dir.length() < 0.1:
		final_push_dir = goat_forward_dir
		print("GoatHorns: Using fallback forward direction")
	
	var push_force := goat_charge_speed * push_force_multiplier
	var push_velocity := final_push_dir * push_force * (1/ target_creature.size)
	if target_creature.size > 300:
		return false
	print("GoatHorns: Pushing ", target_creature.name, " with ", push_velocity)
	target_creature.velocity += push_velocity
	
	return true
