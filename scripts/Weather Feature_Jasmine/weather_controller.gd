extends Node3D

@onready var rain: GPUParticles3D = $Rain
@onready var snow: GPUParticles3D = $Snow

var current_weather := "clear"

func _ready():
	# Start with clear weather
	if rain:
		rain.emitting = false; rain.visible = false
	if snow:
		snow.emitting = false; snow.visible = false
	print("WeatherController read: rain=", rain, " snow=", snow)

# Change weather by name
func set_weather(weather_type: String):
	current_weather = weather_type

	if rain:
		rain.emitting = (weather_type == "rain")
		rain.visible = rain.emitting
	if snow:
		snow.emitting = (weather_type == "snow")
		snow.visible = snow.emitting
		snow.emitting = false
		await get_tree().create_timer(0.1).timeout
		snow.emitting = true
		
	print("Weather ->", weather_type,
	" | rain=", rain and rain.emitting,
	" | snow=",snow and snow.emitting)
