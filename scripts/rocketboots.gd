extends Node

@export var rocket_force: float = 1500.0  # Upward thrust force
@export var rocket_fuel_max: float = 3.0  # Max rocket time in seconds
@export var rocket_recharge_rate: float = 1.0  # Fuel recharge per second

var rocket_fuel: float
var is_rocketing: bool = false
var character: Creature
var planet: Node2D

@export var left_fire_path: NodePath  # Path to left flame sprite
@export var right_fire_path: NodePath  # Path to right flame sprite

@onready var left_rocket_sprite: Sprite2D = get_node(left_fire_path)
@onready var right_rocket_sprite: Sprite2D = get_node(right_fire_path)

func _ready():
	# Get reference to the character (scene root i.e. goatboy)
	character = get_parent() as Creature
	if not character:
		push_error("RocketBoots: Scene root must be Creature")
		return
	
	# Get planet reference
	planet = character.planet
	
	rocket_fuel = rocket_fuel_max
	
	# Make sure rocket sprites start hidden
	if left_rocket_sprite:
		left_rocket_sprite.visible = false
	if right_rocket_sprite:
		right_rocket_sprite.visible = false

func _input(event):
	if not character or character.is_dead:
		print("nocrre")
		return
		
	# Handle W key for rocket boots
	if event is InputEventKey and event.keycode == KEY_W:
		if event.pressed and rocket_fuel > 0.0:
			is_rocketing = true
		else:
			is_rocketing = false

func _physics_process(delta):
	if not character or not planet or character.is_dead:
		planet = character.planet
		return
	
	if is_rocketing and rocket_fuel > 0.0:
		# Calculate up direction relative to planet
		var gravity_dir = (planet.global_position - character.global_position).normalized()
		var up_dir = -gravity_dir
		
		# Apply upward rocket force
		character.velocity += up_dir * rocket_force * delta
		
		# Consume fuel
		rocket_fuel -= delta
		rocket_fuel = max(0.0, rocket_fuel)
		
		# Show rocket sprites
		if left_rocket_sprite:
			left_rocket_sprite.visible = true
		if right_rocket_sprite:
			right_rocket_sprite.visible = true
		
		# Stop rocketing if out of fuel
		if rocket_fuel <= 0.0:
			is_rocketing = false
	else:
		# Not rocketing - recharge fuel and hide sprites
		is_rocketing = false
		rocket_fuel += rocket_recharge_rate * delta
		rocket_fuel = min(rocket_fuel_max, rocket_fuel)
		
		# Hide rocket sprites
		if left_rocket_sprite:
			left_rocket_sprite.visible = false
		if right_rocket_sprite:
			right_rocket_sprite.visible = false
