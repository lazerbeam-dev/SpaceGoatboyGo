extends Node2D
class_name CollarMain

@export var camera: Camera2D
@export var ping_interval := 3.0  # seconds between outbound pings
@export var money_amount := 0
var weapon_controller: CreatureWeaponController = null
var goatboy: Node = null
var collar: Node = null
var control_tower: Node = null
var inited := false
var latest_health: float = -1.0
var health_check_interval := 0.5  # seconds
var health_polling := false
var goatboyHealth: DestructibleShape = null
var mission_polling := false
var mission_check_interval := 1.0  # seconds
var sucker: Node = null
var dead_goatboy = true

@onready var ui := get_node_or_null("CollarUIManager")
@onready var collar_mission: CollarMission = get_node_or_null("CollarMission")
@onready var weapon_pilot: CollarWeaponPilot = get_node_or_null("CollarArmsControl")

func _ready():
	initialize()

func initialize():
	goatboy = Util.get_node_parent_of_type(self, "CharacterBody2D")
	if not goatboy:
		push_error("CollarMain: Could not find Creature parent")
		return
	
	collar = $ControlSystem
	if not collar:
		push_warning("CollarMain: Could not find CollarSystem under Creature")

	sucker = goatboy.get_node_or_null("Proboscis/Sucker")
	if not sucker:
		push_warning("CollarMain: Could not find Sucker under Creature")

func handle_control_payload(payload: Dictionary) -> void:
	#print("Collar received payload:", payload)
	if not camera:
		camera = Utils.get_current_camera()

	var payload_type: String = payload.get("type", "")

	match payload_type:
		"ping":
			if not inited and payload.get("i_am_control_tower", false):
				print("CollarMain: CLAIMING CONTROL as goatboy collar")
			
			control_tower = payload.get("from_node", null)
			await get_tree().create_timer(0.5).timeout  # Let everything stabilize

			if collar:
				collar.control_tower = control_tower

			if camera and goatboy:
				camera.target = goatboy
				print("CollarMain: Camera now following", goatboy.name)

			var arms = get_node_or_null("../Arms")
			if arms:
				arms.camera = camera

			var x: CreatureControlCollar = $CollarCreatureControl
			x.enable_move = true

			inited = true
			health_polling = true
			mission_polling = true
			if arms and arms is CreatureWeaponController:
				weapon_controller = arms
			else:
				push_warning("CollarMain: No weapon controller found at path.")

			if weapon_pilot:
				if weapon_controller:
					weapon_pilot.weapon_controller = weapon_controller
				if camera:
					weapon_pilot.camera = camera
				if goatboy:
					weapon_pilot.facing_right_reference = goatboy
			else:
				push_warning("CollarMain: No weapon pilot child node found.")

			goatboyHealth = goatboy.get_node_or_null("Health")
			
			if payload.has("mission") and collar_mission:
				var mission: Mission = payload["mission"]
				collar_mission.mission = mission
				collar_mission.start_mission()
				print("CollarMain: Mission received and started:", mission.description)

			Utils.current_collar = self
			_send_control_acquired_ping(payload)
			_start_ping_loop()
			_start_health_monitor()
			_start_mission_monitor()

			if is_instance_valid(sucker) and sucker.has_method("enable"):
				sucker.call("enable")

		"control_acquired":
			pass
			#print("CollarMain: Control acquired by", payload.get("from", "?"))

		"hit":
			pass
			#print("CollarMain: Goatboy took hit:", payload.get("amount", 0))

		_:
			pass
			#print("CollarMain: Unhandled payload type:", payload_type)

func _send_control_acquired_ping(original_payload: Dictionary) -> void:
	if not collar:
		return

	var dir := Vector2.UP
	if original_payload.has("from_position"):
		dir = (original_payload["from_position"] - self.global_position)

	var response := {
		"type": "control_acquired",
		"reply_to": original_payload.get("from", "unknown"),
		"source": self,
		"goatboy": goatboy,
		"collar": collar,
		"time": Time.get_unix_time_from_system()
	}
	collar.send_laser(response, dir, goatboy)

func _start_ping_loop() -> void:
	await get_tree().create_timer(ping_interval).timeout
	while inited and is_instance_valid(control_tower) and collar:
		var dir: Vector2 = (control_tower.global_position - self.global_position).normalized()
		var type := "status" if (goatboy and is_instance_valid(goatboy)) else "died"

		var payload := {
			"type": type,
			"origin": goatboy,
			"collar": collar,
			"time": Time.get_unix_time_from_system(),
			"health": latest_health
		}

		if collar_mission and collar_mission.is_active:
			payload["mission"] = collar_mission.get_status_data()

		collar.send_laser(payload, dir, goatboy)
		await get_tree().create_timer(ping_interval).timeout

func _start_mission_monitor() -> void:
	while mission_polling and is_instance_valid(collar_mission):
		if ui and collar_mission:
			collar_mission.update(mission_check_interval, self.global_position)
			ui.update_mission_status(collar_mission.get_status_data())
		await get_tree().create_timer(mission_check_interval).timeout
func on_last_frame() -> void:
	if sucker:
		sucker.disable()
	set_money(0)
	dead_goatboy = true
func _start_health_monitor() -> void:
	while health_polling and is_instance_valid(goatboy) and is_instance_valid(goatboyHealth):
		latest_health = goatboyHealth.get_health_ratio()

		if ui:
			ui.update_goatboy_status({
				"health": latest_health,
				"goatboy": goatboy,
				"position": goatboy.global_position
			})

		if latest_health <= 0.0:
			print("CollarMain: Goatboy dead, releasing control.")
			dead_goatboy = true
			health_polling = false

			if is_instance_valid(sucker) and sucker.has_method("disable"):
				sucker.call("disable")

			break
		else:
			dead_goatboy = false
		await get_tree().create_timer(health_check_interval).timeout
func bump_money(amount: int) -> void:
	if dead_goatboy:
		return
	money_amount += amount
	Utils.hud.display_money(str(money_amount))
	
func set_money(amount: int) -> void:
	money_amount = amount
	Utils.hud.display_money(str(money_amount))
