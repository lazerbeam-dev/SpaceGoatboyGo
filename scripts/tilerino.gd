@tool
extends Node2D
class_name SpriteTiler

@export var texture: Texture2D
@export var tile_size := Vector2(64, 64)
@export var tile_count := Vector2i(5, 1)  # how many tiles in x, y
@export var offset := Vector2.ZERO  # optional offset
@export var regenerate := false:
	set(value):
		regenerate = false
		generate_tiles()

var tile_sprites: Array[Sprite2D] = []

func _ready():
	generate_tiles()

func _process(_delta):
	if Engine.is_editor_hint():
		return
	# Optional: dynamic update logic if needed

func generate_tiles():
	# Clear old
	for sprite in tile_sprites:
		if sprite and sprite.is_inside_tree():
			sprite.queue_free()
	tile_sprites.clear()

	if not texture:
		return

	for y in range(tile_count.y):
		for x in range(tile_count.x):
			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(x * tile_size.x, y * tile_size.y) + offset
			add_child(sprite)
			tile_sprites.append(sprite)
