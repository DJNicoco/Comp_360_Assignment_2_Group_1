extends CanvasLayer

@export_node_path("Node3D") var weather_controller_path

@onready var weather_controller: Node3D = get_node_or_null("/root/Main/WeatherController")

@onready var clear_btn: Button = $WeatherBar/ClearButton
@onready var rain_btn: Button = $WeatherBar/RainButton
@onready var snow_btn: Button = $WeatherBar/SnowButton

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
		
	var root := get_tree().current_scene
	if root:
		weather_controller = root.find_child("WeatherController", true, false)
	print("HUD ready. Found WeatherController =", weather_controller)
	
	if clear_btn: clear_btn.pressed.connect(_on_clear_pressed)
	if rain_btn: rain_btn.pressed.connect(_on_rain_pressed)
	if snow_btn: snow_btn.pressed.connect(_on_snow_pressed)
	
	print("HUD -> WeatherController:", weather_controller)
	
func _on_clear_pressed() -> void:
	if weather_controller and weather_controller.has_method("set_weather"):
		weather_controller.set_weather("clear")
		print("Weather -> Clear")
		
func _on_rain_pressed() -> void:
	if weather_controller and weather_controller.has_method("set_weather"):
		weather_controller.set_weather("rain")
		print("Weather -> Rain")
		
func _on_snow_pressed() -> void:
	if weather_controller and weather_controller.has_method("set_weather"):
		weather_controller.set_weather("snow")
		print("Weather -> Snow")
	
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
	@warning_ignore("integer_division")
	var ms := int(round((time - int(time)) * 1000.0))
	timer_label.text = "Time: %02d:%02d.%03d" % [int(time) / 60, int(time) % 60, ms]


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
	@warning_ignore("integer_division")
	var minutes = int(race_time) / 60
	var seconds = fmod(race_time, 60.0)
	return "%02d:%05.2f" % [minutes, seconds]
