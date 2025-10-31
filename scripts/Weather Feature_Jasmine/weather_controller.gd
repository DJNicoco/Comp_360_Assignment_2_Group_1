extends Node3D

@export var follow_target: NodePath            
@export var road_collision_mask: int = 1       
@export var height_offset: float = 20.0        
@export var use_rain_on_start: bool = false    

@onready var rain: GPUParticles3D = $Rain
@onready var snow: GPUParticles3D = $Snow
@onready var _target: Node3D = get_node_or_null(follow_target)

@export var path_to_track: NodePath
@export var tile_scene: PackedScene
@export var spacing_m: float = 80.0
@export var tile_y_offset: float = 40.0
@export var build_tiles_on_start: bool = false

var _tiles_parent: Node3D
var current_weather := "clear"

func _ready() -> void:
	if use_rain_on_start:
		_apply_weather("rain")
	else:
		_apply_weather("clear")
	print("WeatherController ready: rain=", rain, " snow=", snow)
	if build_tiles_on_start:
		build_track_emitters()

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
	if _target == null:
		return

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
	
func build_track_emitters() -> void:
	var p: Path3D = get_node_or_null(path_to_track)
	if p == null or tile_scene == null:
		push_warning("Assign path_to_track and tile_scene on WeatherController.")
		return

	# Clear previous tiles if rebuilding
	if _tiles_parent and is_instance_valid(_tiles_parent):
		_tiles_parent.queue_free()

	_tiles_parent = Node3D.new()
	_tiles_parent.name = "WeatherTiles"
	add_child(_tiles_parent)

	var c := p.curve
	var L := c.get_baked_length()
	var d: float = 0.0
	while d <= L:
	# 1) Sample the curve (LOCAL to Path3D)
		var local_pos: Vector3 = c.sample_baked(d)

	# 2) Convert to WORLD space using the Path3D node
		var world_pos: Vector3 = p.to_global(local_pos)

	# 3) Instance, add to scene, THEN set its global position
		var tile := tile_scene.instantiate()
		tile.name = "WeatherTile_%03d" % int(d)
		_tiles_parent.add_child(tile)                         # <-- add first
		tile.global_position = world_pos + Vector3.UP * tile_y_offset

		d += spacing_m

	_apply_material_to_tiles()   # sync tiles with current weather
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
