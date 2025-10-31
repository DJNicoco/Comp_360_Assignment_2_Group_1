extends Node3D

@export var follow_target: NodePath          
@export var road_collision_mask: int = 1
@export var height_offset: float = 20.0
@export var use_rain_on_start: bool = false

@onready var rain: GPUParticles3D = $Rain
@onready var snow: GPUParticles3D = $Snow
@onready var _target: Node3D = get_node_or_null(follow_target)

@export var camera_path: NodePath             
@export var depth: float = 80.0             
@export var margin: float = 10.0               
var _cam: Camera3D = null

var _tiles_parent: Node3D
var current_weather := "clear"

func _ready() -> void:
	if camera_path != NodePath():
		_cam = get_node_or_null(camera_path) as Camera3D
	else:
		_cam = get_viewport().get_camera_3d()

	_configure_particles(rain)
	_configure_particles(snow)

	# Initial weather
	if use_rain_on_start:
		_apply_weather("rain")
	else:
		_apply_weather("clear")

	_resize_emitters_to_view()

func set_weather(weather_type: String) -> void:
	if weather_type == current_weather:
		return
	_apply_weather(weather_type)
	print("Weather ->", weather_type,
		" | rain=", rain and rain.emitting,
		" | snow=", snow and snow.emitting)

func _apply_weather(state: String) -> void:
	current_weather = state

	var r_on := state == "rain"
	var s_on := state == "snow"

	if rain:
		rain.visible = r_on
		rain.emitting = r_on

	if snow:
		if s_on:
			snow.visible = true
			snow.emitting = false
			await get_tree().process_frame
			snow.emitting = true
		else:
			snow.emitting = false
			snow.visible = false

func _physics_process(_dt: float) -> void:
	if _cam == null:
		_cam = get_viewport().get_camera_3d()

	if _target != null:
		var base := _target.global_transform.origin
		var from := base + Vector3.UP * 150.0
		var to   := base + Vector3.DOWN * 300.0

		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.collision_mask = road_collision_mask
		var hit := space.intersect_ray(q)

		var pos := base
		if hit.has("position"):
			pos.y = hit.position.y + height_offset
		else:
			pos.y += height_offset
		global_transform.origin = pos

	_resize_emitters_to_view()

func _configure_particles(p: GPUParticles3D) -> void:
	if p == null:
		return
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-200, -200, -200), Vector3(400, 400, 400))

func _emitters() -> Array:
	var arr: Array = []
	if rain != null:
		arr.append(rain)
	if snow != null:
		arr.append(snow)
	return arr

func _resize_emitters_to_view() -> void:
	if _cam == null:
		return

	var vp_size: Vector2i = get_viewport().size
	var aspect: float = float(vp_size.x) / max(1.0, float(vp_size.y))

	var half_h: float = tan(deg_to_rad(_cam.fov * 0.5)) * depth
	var half_w: float = half_h * aspect
	var extents := Vector3(half_w + margin, half_h + margin, depth * 0.5 + margin)

	for p in _emitters():
		p.set("emission_box_extents", extents)

		var t: Transform3D = _cam.global_transform
		t.origin = Vector3(global_transform.origin.x, _cam.global_transform.origin.y, global_transform.origin.z)
		t = t.translated_local(Vector3(0, 0, -depth * 0.5))
		p.global_transform = t
