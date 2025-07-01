extends Node
class_name SlimeAI

var parent: Node = null
var stuck_timer := 0.0
var stuck_threshold := 0.1
var stuck_time_limit := 1.0  # seconds of being nearly still before escape
var escape_dir := 0.0

func _ready():
	parent = get_parent()
	if not parent:
		push_error("SlimeAI must be child of a Slime")

func _process(_delta):
	pass
	#if not parent or not parent.planet:
		#return
#
	## Measure tangential speed
	#var gravity_dir = (parent.planet.global_position - parent.global_position).normalized()
	#var up_dir = -gravity_dir
	#var right_dir = Vector2(-up_dir.y, up_dir.x)
#
	#var tangent_speed = parent.velocity.dot(right_dir)
#
	#if abs(tangent_speed) < stuck_threshold:
		#stuck_timer += delta
	#else:
		#stuck_timer = 0.0
#
	## Escape behavior: apply a directional nudge
	#if stuck_timer > stuck_time_limit:
		#if escape_dir == 0.0:
			#escape_dir = randf_range(-1.0, 1.0)  # pick a random tangential direction
#
		#parent.move_input = escape_dir
	#else:
		## Default state: no movement input, let bounce physics do the work
		#parent.move_input = 0.0
		#escape_dir = 0.0
