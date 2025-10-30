extends VehicleBody3D

@export var max_steer: float    = 0.6
@export var engine_power: float = 1200.0
@export var brake_power: float  = 30.0

const ROAD_LAYER: int = 1          # your road prints layer=1
const PROBE_LEN: float  = 50.0
const SNAP_OFFSET: float = 0.45

var _ready_to_drive := false

func _ready() -> void:
	# 1) Physics bodies must not be scaled
	scale = Vector3.ONE

	# 2) Make sure the chassis actually has a collider (box). If it already exists, we leave it.
	_ensure_chassis_shape()

	# 3) Ensure collision layers/masks MATCH the road (layer 1).
	collision_layer = 0
	collision_mask  = 0
	set_collision_layer_value(ROAD_LAYER, true)
	set_collision_mask_value(ROAD_LAYER, true)

	# 4) Wheel roles + safe defaults (only set props that exist in 4.5)
	for n in get_children():
		if n is VehicleWheel3D:
			var w := n as VehicleWheel3D
			w.scale = Vector3.ONE
			var nm := w.name.to_lower()
			_set_if_present(w, "use_as_steering", nm.begins_with("front"))
			_set_if_present(w, "use_as_traction", nm.begins_with("rear"))
			_try(w, "wheel_radius", 0.45)          # slightly larger so they reach
			_try(w, "radius", 0.45)
			_try(w, "rest_length", 0.45)
			_try(w, "suspension_travel", 0.40)
			_try(w, "suspension_stiffness", 30.0)
			_try(w, "suspension_max_force", 20000.0)
			_try(w, "damping_compression", 3.0)
			_try(w, "damping_relaxation", 3.0)
			_try(w, "friction_slip", 2.0)
			_try(w, "roll_influence", 0.1)

func _physics_process(delta: float) -> void:
	if not _ready_to_drive:
		_snap_to_road_once()
		return

	# Driving
	var steer_in := Input.get_axis("left", "right")
	var throttle := Input.get_axis("down", "up")
	steering     = move_toward(steering, steer_in * max_steer, delta * 5.0)
	engine_force = throttle * engine_power

	var braking := 0.0
	if throttle != 0.0 and sign(linear_velocity.z) * throttle < 0.0:
		braking = brake_power
	brake = braking

# --- one-time snap so suspension starts in contact ---
func _snap_to_road_once() -> void:
	var from: Vector3 = global_transform.origin + Vector3.UP * 5.0
	var to: Vector3   = from + Vector3.DOWN * PROBE_LEN

	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = _mask_from_index(ROAD_LAYER)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)

	if hit.is_empty():
		# last resort: try all layers once to avoid layer mis-match edge cases
		var q_all: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		q_all.collision_mask = 0x7FFFFFFF
		hit = get_world_3d().direct_space_state.intersect_ray(q_all)
		if hit.is_empty():
			push_warning("Car probe: no collider under car on ANY layer.")
			return

	var pos: Transform3D = global_transform
	pos.origin.y = (hit["position"] as Vector3).y + SNAP_OFFSET
	global_transform = pos

	# Kill any residual velocity at spawn so it doesn’t tunnel through
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	_ready_to_drive = true
	print("Car snapped to road at ", hit["position"])

# --- create a box collider for the chassis if missing ---
func _ensure_chassis_shape() -> void:
	var shape_node := get_node_or_null("ChassisShape") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "ChassisShape"
		add_child(shape_node)
	# size it to something reasonable under the car (adjust if your mesh is larger)
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 0.6, 3.2)  # width, height, length — tweak to your model
	shape_node.shape = box
	# Put the car collider on the same layer and colliding with road
	shape_node.set_owner(get_tree().edited_scene_root if Engine.is_editor_hint() else self)

# --- utils ---
func _mask_from_index(i: int) -> int:
	return 1 << (i - 1)

func _has_prop(o: Object, prop_name: String) -> bool:
	for d in o.get_property_list():
		if d.name == prop_name:
			return true
	return false

func _set_if_present(o: Object, prop_name: String, value) -> void:
	if _has_prop(o, prop_name):
		o.set(prop_name, value)

func _try(o: Object, prop_name: String, value) -> void:
	_set_if_present(o, prop_name, value)
