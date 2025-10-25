extends CanvasLayer

@onready var timer_label = $MarginContainer/VBoxContainer/Timer
@onready var speed_label = $MarginContainer/VBoxContainer/Speed
@onready var lap_label = $MarginContainer/VBoxContainer/Lap
@onready var message_label = $CenterContainer/MessageLabel

var race_time: float = 0.0
var is_racing: bool = false
var current_lap: int = 1
var total_laps: int = 3

func _ready():
	# Debug: Check if nodes exist
	if not timer_label:
		push_error("Timer label not found! Check node path: MarginContainer/VBoxContainer/Timer")
	if not speed_label:
		push_error("Speed label not found! Check node path: MarginContainer/VBoxContainer/Speed")
	if not lap_label:
		push_error("Lap label not found! Check node path: MarginContainer/VBoxContainer/Lap")
	if not message_label:
		push_error("Message label not found! Check node path: CenterContainer/MessageLabel")
	
	# Only update if nodes exist
	if timer_label and speed_label and lap_label and message_label:
		update_timer(0.0)
		update_speed(0.0)
		update_lap(1, total_laps)
		message_label.text = ""

func _process(delta):
	if is_racing:
		race_time += delta
		update_timer(race_time)

func start_race():
	is_racing = true
	race_time = 0.0
	current_lap = 1
	if message_label:
		message_label.text = ""
	update_lap(current_lap, total_laps)

func stop_race():
	is_racing = false

func set_total_laps(laps: int):
	total_laps = laps
	update_lap(current_lap, total_laps)

func increment_lap():
	current_lap += 1
	update_lap(current_lap, total_laps)
	
	# Show lap completion message
	if current_lap <= total_laps:
		show_message("Lap %d / %d" % [current_lap, total_laps], 2.0)

func get_current_lap() -> int:
	return current_lap

func update_timer(time: float):
	if not timer_label:
		return
	var minutes = int(time) / 60
	var seconds = fmod(time, 60.0)
	timer_label.text = "Time: %02d:%05.2f" % [minutes, seconds]

func update_speed(speed_mps: float):
	if not speed_label:
		return
	# Convert m/s to km/h
	var speed_kmh = speed_mps * 3.6
	speed_label.text = "Speed: %d km/h" % int(speed_kmh)

func update_lap(current: int, total: int):
	if not lap_label:
		return
	lap_label.text = "Lap: %d / %d" % [current, total]

func show_message(text: String, duration: float = 0.0):
	if not message_label:
		return
	message_label.text = text
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		if message_label:
			message_label.text = ""

func get_final_time() -> String:
	var minutes = int(race_time) / 60
	var seconds = fmod(race_time, 60.0)
	return "%02d:%05.2f" % [minutes, seconds]
