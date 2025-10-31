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

@export var path_to_track: NodePath
@export var tile_scene: PackedScene
@export var spacing_m: float = 80.0
@export var tile_y_offset: float = 40.0
@export var build_tiles_on_start: bool = false

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

	if build_tiles_on_start:
		build_track_emitters()

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

	_apply_material_to_tiles()

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

func build_track_emitters() -> void:
	var p: Path3D = get_node_or_null(path_to_track)
	if p == null or tile_scene == null:
		push_warning("Assign path_to_track and tile_scene on WeatherController.")
		return

	if _tiles_parent and is_instance_valid(_tiles_parent):
		_tiles_parent.queue_free()

	_tiles_parent = Node3D.new()
	_tiles_parent.name = "WeatherTiles"
	add_child(_tiles_parent)

	var c := p.curve
	var L := c.get_baked_length()
	var d: float = 0.0
	while d <= L:
		var local_pos: Vector3 = c.sample_baked(d)
		var world_pos: Vector3 = p.to_global(local_pos)

		var tile := tile_scene.instantiate()
		tile.name = "WeatherTile_%03d" % int(d)
		_tiles_parent.add_child(tile)
		tile.global_position = world_pos + Vector3.UP * tile_y_offset

		d += spacing_m

	_apply_material_to_tiles()
	print("Built weather tiles:", _tiles_parent.get_child_count())

func _apply_material_to_tiles() -> void:
	if _tiles_parent == null:
		return

	var mat: ParticleProcessMaterial = null
	if current_weather == "rain" and rain:
		mat = (rain.process_material as ParticleProcessMaterial).duplicate(true)
	elif current_weather == "snow" and snow:
		mat = (snow.process_material as ParticleProcessMaterial).duplicate(true)

	for tile in _tiles_parent.get_children():
		var gp := tile.get_node_or_null("Precip") as GPUParticles3D
		if gp:
			if mat:
				gp.process_material = mat.duplicate(true)
				gp.emitting = true
			else:
				gp.emitting = false
