extends Node

@export var snow_path: NodePath      # assign your GPUParticles3D Snow node
@export var camera_path: NodePath    # assign your active Camera3D
@export var depth: float = 80.0      # how far in front of camera to fill
@export var margin: float = 10.0     # padding around the edges
@export var wind_world: Vector3 = Vector3(0.7, 0.0, 0.0)  # optional sideways drift in world space

var snow: GPUParticles3D
var cam: Camera3D

func _ready() -> void:
	# Grab nodes
	snow = get_node(snow_path) as GPUParticles3D
	cam  = get_node(camera_path) as Camera3D

	# Important runtime settings
	snow.local_coords = false
	# Prevent culling when the box is large:
	snow.visibility_aabb = AABB(-Vector3(200, 200, 200), Vector3(400, 400, 400))

	# Gentle defaults for snow in the material if present
	_configure_snow_material()

	_resize_to_view()
	_update_transform()

func _physics_process(_dt: float) -> void:
	_update_transform()
	_resize_to_view()
	_apply_wind_drift()

func _update_transform() -> void:
	# Put the emitter box in front of the camera, facing the same way
	snow.global_transform = cam.global_transform
	snow.translate_object_local(Vector3(0, 0, -depth * 0.5))

func _resize_to_view() -> void:
	# Size the box to cover the entire viewport (width/height) at "depth"
	var vp_size: Vector2i = get_viewport().size
	var aspect: float = float(vp_size.x) / max(1.0, float(vp_size.y))

	var half_h: float = tan(deg_to_rad(cam.fov * 0.5)) * depth
	var half_w: float = half_h * aspect

	# Set via generic setter to avoid compile-time property lookup issues
	snow.set("emission_box_extents", Vector3(half_w + margin, half_h + margin, depth * 0.5 + margin))

func _configure_snow_material() -> void:
	# If your Snow node has a ParticleProcessMaterial assigned, set some nice defaults
	var ppm := snow.process_material
	if ppm == null:
		return
	if ppm is ParticleProcessMaterial:
		var m := ppm as ParticleProcessMaterial
		# Slow fall; snow shouldn’t streak like rain
		m.gravity = Vector3(0, -2.5, 0)          # gentle downward pull
		m.initial_velocity_min = 0.2
		m.initial_velocity_max = 0.9
		m.linear_accel_min = 0.0
		m.linear_accel_max = 0.4
		# Random rotation for flakes
		m.angle_min = -15.0
		m.angle_max = 15.0
		m.angular_velocity_min = -1.0
		m.angular_velocity_max = 1.5
		# Slight spread so it’s not perfectly vertical
		m.spread = 8.0
		# Optional scale tweaking (if you use a quad/mesh draw pass)
		m.scale_min = 0.6
		m.scale_max = 1.2

func _apply_wind_drift() -> void:
	# Nudge the emitter sideways to simulate wind carrying flakes across view.
	# Particles stay in world (local_coords=false), so already-spawned flakes won’t “stick” to the emitter.
	if wind_world.length() == 0.0:
		return
	# Move a little per frame in camera's local XZ based on world wind vector projected into camera space.
	# Simpler alternative: just offset global position by wind_world * small factor.
	var drift_per_second: float = 2.0
	var offset: Vector3 = wind_world.normalized() * drift_per_second * get_physics_process_delta_time()
	snow.global_position += offset
