extends Node

enum GameState {
	WAITING,
	COUNTDOWN,
	RACING,
	FINISHED
}

@export var vehicle_path: NodePath
@export var start_trigger_path: NodePath
@export var finish_trigger_path: NodePath
@export var countdown_duration: float = 3.0
@export var total_laps: int = 3

var current_state: GameState = GameState.WAITING
var vehicle: Node3D
var start_trigger: Area3D
var finish_trigger: Area3D
var hud: CanvasLayer
var current_lap: int = 1

func _ready():
	# Get references
	if vehicle_path:
		vehicle = get_node(vehicle_path)
	if start_trigger_path:
		start_trigger = get_node(start_trigger_path)
	if finish_trigger_path:
		finish_trigger = get_node(finish_trigger_path)
		
	# Find HUD - try multiple paths
	hud = get_node_or_null("../HUD")
	if not hud:
		hud = get_node_or_null("/root/Main/HUD")
	if not hud:
		hud = get_node_or_null("/root/TestMain/HUD")
	
	if hud and hud.has_method("set_total_laps"):
		hud.set_total_laps(total_laps)
	
	# Start in waiting state
	change_state(GameState.WAITING)

func _process(_delta):
	# Update speed display if racing
	if current_state == GameState.RACING and vehicle:
		var speed = get_vehicle_speed()
		if hud:
			hud.update_speed(speed)

func change_state(new_state: GameState):
	current_state = new_state
	
	match current_state:
		GameState.WAITING:
			current_lap = 1
			if hud:
				hud.show_message("Enter the start area to begin!")
		
		GameState.COUNTDOWN:
			start_countdown()
		
		GameState.RACING:
			if hud:
				hud.start_race()
		
		GameState.FINISHED:
			if hud:
				hud.stop_race()
				var final_time = hud.get_final_time()
				hud.show_message("Race Complete!\nFinal Time: " + final_time, 5.0)

func start_countdown():
	if hud:
		disable_vehicle_controls(true)
		
		for i in range(int(countdown_duration), 0, -1):
			hud.show_message(str(i), 1.0)
			await get_tree().create_timer(1.0).timeout
		
		hud.show_message("GO!", 1.0)
		disable_vehicle_controls(false)
		change_state(GameState.RACING)

func _on_start_trigger_entered(body):
	if body == vehicle and current_state == GameState.WAITING:
		change_state(GameState.COUNTDOWN)

func _on_finish_trigger_entered(body):
	if body != vehicle or current_state != GameState.RACING:
		return
	
	# Increment lap
	current_lap += 1
	
	if hud:
		hud.increment_lap()
	
	# Check if race is complete
	if current_lap > total_laps:
		change_state(GameState.FINISHED)
	else:
		# Continue racing - show lap message (HUD handles this)
		print("Lap ", current_lap, " / ", total_laps)

func get_vehicle_speed() -> float:
	# Get vehicle's linear velocity magnitude
	if vehicle and vehicle.has_method("get_linear_velocity"):
		return vehicle.get_linear_velocity().length()
	elif vehicle:
		# Fallback: calculate from position change
		return 0.0
	return 0.0

func disable_vehicle_controls(disabled: bool):
	# Disable/enable vehicle input during countdown
	if vehicle and vehicle.has_method("set_controls_enabled"):
		vehicle.set_controls_enabled(!disabled)
	elif vehicle and vehicle.has_method("set_process_input"):
		vehicle.set_process_input(!disabled)
