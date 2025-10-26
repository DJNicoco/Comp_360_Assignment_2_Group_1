extends Node3D

@onready var rain = $Rain
@onready var snow = $Snow

var current_weather = "clear"

func _ready():
	# Start with clear weather
	rain.emitting = false
	snow.emitting = false

# Change weather by name
func set_weather(weather_type: String):
	current_weather = weather_type

	if weather_type == "rain":
		rain.emitting = true
		snow.emitting = false

	elif weather_type == "snow":
		rain.emitting = false
		snow.emitting = true

	elif weather_type == "clear":
		rain.emitting = false
		snow.emitting = false
