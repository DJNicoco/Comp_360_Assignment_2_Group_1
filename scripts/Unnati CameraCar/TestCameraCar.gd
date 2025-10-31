# res://scripts/CameraCar.gd
extends VehicleBody3D

# ---------- Driving tunables ----------
@export var max_engine_force: float = 1500.0
@export var max_brake: float       = 60.0
@export var max_steer: float       = 0.6
@export var steer_speed: float     = 5.0   # steering easing speed

# ---------- Camera tunables ----------
@export var cam_distance: float    = 6.5
@export var cam_height: float      = 2.2
@export var cam_side: float        = 0.0
@export var cam_pos_ease: float    = 6.0
@export var cam_rot_ease: float    = 4.0
@export var cam_look_ahead: float  = 2.0

@export var fov_min: float         = 70.0
@export var fov_max: float         = 85.0
@export var fov_speed_for_max: float = 35.0

# ---------- Cached nodes ----------
var _spring: SpringArm3D = null
var _cam: Camera3D = null

# ---------- Internal camera state ----------
var _cam_pos: Vector3 = Vector3.ZERO

# ---------- Wheel contact debug ----------
var _wheels: Array[VehicleWheel3D] = []
var _contact_print_timer: float = 0.0


func _ready() -> void:
	_spring = get_node_or_null("SpringArm3D") as SpringArm3D
	if _spring != null:
		_cam = _spring.get_node_or_null("Camera3D") as Camera3D
	if _cam == null:
		_cam = get_node_or_null("Camera3D") as Camera3D

	_wheels.clear()
	for c in get_children():
		if c is VehicleWheel3D:
			_wheels.append(c as VehicleWheel3D)

	if _wheels.is_empty():
		push_error("PlayerCar has no VehicleWheel3D children.")
	if _cam == null:
		push_error("No Camera3D found (optionally put it under SpringArm3D).")

	if _cam != null:
		_cam_pos = _desired_cam_pos()
	# engine_force = 800.0   # optional shove for testing


func _physics_process(delta: float) -> void:
	# ----- inputs -----
	var throttle: float = Input.get_action_strength("up") - Input.get_action_strength("back")
	var steer_in: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var braking: float  = Input.get_action_strength("handbrake")

	# ----- easing -----
	var next_engine: float = lerp(engine_force, throttle * max_engine_force, 6.0 * delta)
	var next_steer: float  = lerp(steering,     steer_in  * max_steer,       steer_speed * delta)

	# ----- apply to vehicle -----
	engine_force = next_engine
	steering     = next_steer
	brake        = braking * max_brake

	# ----- camera follow -----
	_update_camera(delta)

	# ----- wheel contact debug -----
	var contact_count: int = 0
	for w in _wheels:
		if w.is_in_contact():
			contact_count += 1

	_contact_print_timer += delta
	if _contact_print_timer >= 0.5:
		_contact_print_timer = 0.0
		print("[CarDbg] v=%.1f  throttle=%.2f steer=%.2f  engine=%.0f  wheels_in_contact=%d/%d"
			% [linear_velocity.length(), throttle, steer_in, engine_force, contact_count, _wheels.size()])

	if contact_count == 0:
		apply_central_force(Vector3.DOWN * 2000.0)


# ---------- Camera helpers ----------
func _desired_cam_pos() -> Vector3:
	var basis: Basis  = global_transform.basis
	var fwd: Vector3  = -basis.z.normalized()
	var right: Vector3 = basis.x.normalized()
	var origin: Vector3 = global_transform.origin
	return origin - fwd * cam_distance + Vector3.UP * cam_height + right * cam_side


func _desired_cam_basis(desired_pos: Vector3) -> Basis:
	var fwd: Vector3 = -global_transform.basis.z.normalized()
	var vel_dir: Vector3 = fwd
	if linear_velocity.length() > 0.1:
		vel_dir = linear_velocity.normalized()

	var look_target: Vector3 = global_transform.origin + vel_dir * cam_look_ahead + Vector3.UP * 0.5
	var aim: Vector3 = (look_target - desired_pos).normalized()
	return Basis().looking_at(aim, Vector3.UP)


func _update_camera(delta: float) -> void:
	if _cam == null:
		return

	var desired_pos: Vector3   = _desired_cam_pos()
	var desired_basis: Basis   = _desired_cam_basis(desired_pos)

	# Smooth position
	_cam_pos = _cam_pos.lerp(desired_pos, clamp(cam_pos_ease * delta, 0.0, 1.0))

	# Smooth rotation (slerp)
	var current_basis: Basis = _cam.global_transform.basis
	if _spring != null:
		current_basis = _spring.global_transform.basis

	var new_quat: Quaternion  = Quaternion(current_basis).slerp(Quaternion(desired_basis), clamp(cam_rot_ease * delta, 0.0, 1.0))
	var new_basis: Basis = Basis(new_quat)

	if _spring != null:
		_spring.global_transform = Transform3D(new_basis, _cam_pos)
	else:
		_cam.global_transform = Transform3D(new_basis, _cam_pos)

	# Dynamic FOV by speed
	var spd: float = linear_velocity.length()
	var t: float   = clamp(spd / max(0.001, fov_speed_for_max), 0.0, 1.0)
	var target_fov: float = lerp(fov_min, fov_max, t)
	_cam.fov = lerp(_cam.fov, target_fov, 3.0 * delta)
