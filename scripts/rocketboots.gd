extends Node
@export var rocket_force: float = 1500.0  # Upward thrust force
@export var rocket_fuel_max: float = 3.0  # Max rocket time in seconds
@export var rocket_recharge_rate: float = 1.0  # Fuel recharge per second
@export var horizontal_flying_force_multiplier: float = 0.75  # Horizontal thrust scale when flying

@export var left_fire_path: NodePath
@export var right_fire_path: NodePath

var rocket_fuel: float
var is_rocketing: bool = false
var was_rocketing: bool = false

var character: Creature
var planet: Node2D

@onready var left_rocket_sprite: Sprite2D = get_node_or_null(left_fire_path)
@onready var right_rocket_sprite: Sprite2D = get_node_or_null(right_fire_path)

func _ready():
	character = get_parent() as Creature
	if not character:
		push_error("RocketBoots must be child of a Creature")
		return
	
	planet = character.planet
	rocket_fuel = rocket_fuel_max
	
	if left_rocket_sprite:
		left_rocket_sprite.visible = false
	if right_rocket_sprite:
		right_rocket_sprite.visible = false

func _physics_process(delta):
	if not character or character.is_dead:
		return

	if not planet:
		planet = character.planet
		if not planet:
			return

	var in_true_flying_mode := false
	if character is Goatboy:
		in_true_flying_mode = character.goat_mode_held and is_rocketing and rocket_fuel > 0.0
		character.set_flying_with_rocket_boots(in_true_flying_mode)

	if is_rocketing and rocket_fuel > 0.0:
		var gravity_dir = (planet.global_position - character.global_position).normalized()
		var up_dir = character.up_direction
		var upward_speed = character.velocity.dot(up_dir)
		var scale = 1.0 - clamp(upward_speed / rocket_force, 0.0, 1.0)

		

		if in_true_flying_mode:
			var horizontal_dir: Vector2
			if character.facing_right:
				horizontal_dir = Vector2(-up_dir.y, up_dir.x)
			else:
				horizontal_dir = Vector2(up_dir.y, -up_dir.x)
			character.velocity += horizontal_dir * rocket_force * horizontal_flying_force_multiplier * delta
		else:
			character.velocity += up_dir * rocket_force * scale * delta
		rocket_fuel = max(0.0, rocket_fuel - delta)

		if left_rocket_sprite:
			left_rocket_sprite.visible = true
		if right_rocket_sprite:
			right_rocket_sprite.visible = true

		if rocket_fuel <= 0.0:
			is_rocketing = false
	else:
		rocket_fuel = min(rocket_fuel + rocket_recharge_rate * delta, rocket_fuel_max)

		if was_rocketing and not is_rocketing:
			if left_rocket_sprite:
				left_rocket_sprite.visible = false
			if right_rocket_sprite:
				right_rocket_sprite.visible = false

		if character is Goatboy:
			character.set_flying_with_rocket_boots(false)

	was_rocketing = is_rocketing

# --- External control API ---

func set_rocketing(state: bool) -> void:
	if character and not character.is_dead:
		is_rocketing = state and rocket_fuel > 0.0

func is_currently_rocketing() -> bool:
	return is_rocketing
