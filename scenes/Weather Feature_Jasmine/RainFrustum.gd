extends Node

@export var rain_path: NodePath      # assign your GPUParticles3D "Rain"
@export var camera_path: NodePath    # assign your Camera3D
@export var depth: float = 80.0
@export var margin: float = 10.0

var rain: GPUParticles3D
var cam: Camera3D

func _ready() -> void:
	# Grab nodes
	rain = get_node(rain_path) as GPUParticles3D
	cam  = get_node(camera_path) as Camera3D

	# Set these once in Inspector on the Rain node:
	#   Spawn → Emission Shape = Box
	#   (leave shape/amount/lifetime as you like)

	# Runtime settings that are always safe to set:
	rain.local_coords = false
	# Keep particles from getting culled when the box is large:
	rain.visibility_aabb = AABB(-Vector3(200,200,200), Vector3(400,400,400))

	_resize_to_view()
	_update_transform()

func _physics_process(_dt: float) -> void:
	_update_transform()
	_resize_to_view()

func _update_transform() -> void:
	# Place the emitter box in front of the camera
	rain.global_transform = cam.global_transform
	rain.translate_object_local(Vector3(0, 0, -depth * 0.5))

func _resize_to_view() -> void:
	# Size the box to cover the whole viewport in world space at "depth"
	var vp_size: Vector2i = get_viewport().size
	var aspect: float = float(vp_size.x) / max(1.0, float(vp_size.y))

	var half_h: float = tan(deg_to_rad(cam.fov * 0.5)) * depth
	var half_w: float = half_h * aspect

	# Use set("...") to avoid compile-time property lookup errors
	rain.set("emission_box_extents", Vector3(half_w + margin, half_h + margin, depth * 0.5 + margin))
