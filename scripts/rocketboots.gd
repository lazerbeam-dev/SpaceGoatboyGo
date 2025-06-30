extends Node
@export var rocket_boost_impulse: float = 500.0  # Initial kick when starting
@export var rocket_force: float = 1500.0  # Upward thrust force
@export var rocket_fuel_max: float = 3.0  # Max rocket time in seconds
@export var rocket_recharge_rate: float = 1.0  # Fuel recharge per second
@export var horizontal_flying_force_multiplier: float = 0.75 # Adjust this to control how much horizontal thrust there is when flying
var rocket_fuel: float
var is_rocketing: bool = false
var character: Creature
var planet: Node2D
@export var left_fire_path: NodePath  # Path to left flame sprite
@export var right_fire_path: NodePath  # Path to right flame sprite
@onready var left_rocket_sprite: Sprite2D = get_node(left_fire_path)
@onready var right_rocket_sprite: Sprite2D = get_node(right_fire_path)
var was_rocketing: bool = false

func _ready():
	character = get_parent() as Creature
	if not character:
		push_error("RocketBoots: Scene root must be Creature")
		return
	
	planet = character.planet
	rocket_fuel = rocket_fuel_max
	
	if left_rocket_sprite:
		left_rocket_sprite.visible = false
	if right_rocket_sprite:
		right_rocket_sprite.visible = false

func _input(event):
	if not character or character.is_dead:
		return
		
	if event is InputEventKey and event.keycode == KEY_W:
		if event.pressed and rocket_fuel > 0.0:
			is_rocketing = true
		else:
			is_rocketing = false

func _physics_process(delta):
	if not character or not planet or character.is_dead:
		if character and not planet:
			planet = character.planet
		return
	
	# Determine if Goatboy is in the "true flying" state (goat mode + rocketing)
	var in_true_flying_mode = false
	if character is Goatboy: # Ensure it's a Goatboy instance to access goat_mode_held
		in_true_flying_mode = character.goat_mode_held and is_rocketing and rocket_fuel > 0.0
		character.set_flying_with_rocket_boots(in_true_flying_mode) # Update Goatboy's state immediately
	
	if is_rocketing and rocket_fuel > 0.0:
		var gravity_dir = (planet.global_position - character.global_position).normalized()
		var up_dir = -gravity_dir # This is always the "up" relative to the planet
		
		# Apply base upward rocket force
		character.velocity += up_dir * rocket_force * delta

		
		if in_true_flying_mode:
			# Calculate horizontal direction relative to the planet surface
			# This is perpendicular to the gravity direction
			var horizontal_dir: Vector2
			if character.facing_right:
				# Right relative to planet surface (90 degrees clockwise from up_dir)
				horizontal_dir = Vector2(up_dir.y, -up_dir.x)
			else:
				# Left relative to planet surface (90 degrees counter-clockwise from up_dir)
				horizontal_dir = Vector2(-up_dir.y, up_dir.x)
				
			character.velocity += horizontal_dir * rocket_force * horizontal_flying_force_multiplier * delta
		elif not was_rocketing:
			character.velocity += up_dir * rocket_boost_impulse
		# ONLY apply horizontal force if in "true flying" mode
		rocket_fuel -= delta
		rocket_fuel = max(0.0, rocket_fuel)
		
		if left_rocket_sprite:
			left_rocket_sprite.visible = true
		if right_rocket_sprite:
			right_rocket_sprite.visible = true
		
		if rocket_fuel <= 0.0:
			is_rocketing = false
	else:
		# If not rocketing (or ran out of fuel), recharge
		rocket_fuel += rocket_recharge_rate * delta
		rocket_fuel = min(rocket_fuel_max, rocket_fuel)
		
		# Hide sprites on transition or if not actively rocketing
		if was_rocketing and not is_rocketing:
			if left_rocket_sprite:
				left_rocket_sprite.visible = false
			if right_rocket_sprite:
				right_rocket_sprite.visible = false
		
		# Ensure Goatboy's flying state is false when not rocketing
		if character is Goatboy:
			character.set_flying_with_rocket_boots(false)
	
	was_rocketing = is_rocketing
