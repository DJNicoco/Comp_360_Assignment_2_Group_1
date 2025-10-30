extends VehicleBody3D

@export var max_rpm: int    = 500
@export var max_torque: int = 200

# ---- safety / snapping knobs ----
const ROAD_LAYER_BIT := 1             # the bit your road StaticBody3D uses
const PROBE_LEN      := 50.0          # how far down we raycast
const SNAP_OFFSET    := 0.20          # lift car slightly above hit point
const FALL_SPEED_Y   := -6.0          # if vertical speed is below this...
const FALL_FRAMES    := 6             # ...for this many frames -> resnap
const SAFE_FLOOR_Y   := -200.0        # hard floor: don’t let car go below this

var _dss: PhysicsDirectSpaceState3D
var _fall_counter := 0
var _snapped_once := false

func _ready() -> void:
	# Never scale physics nodes
	scale = Vector3.ONE

	# Put car on the same layer/mask as road rays (not strictly required for rays, but consistent)
	collision_layer = 0
	collision_mask  = 0
	set_collision_layer_value(ROAD_LAYER_BIT, true)
	set_collision_mask_value(ROAD_LAYER_BIT, true)

	# Neutralize any accidental wheel rot/scale that breaks suspension rays
	for n in get_children():
		if n is VehicleWheel3D:
			n.transform.basis = Basis()     # zero rotation on the wheel node
			n.scale = Vector3.ONE

	_dss = get_world_3d().direct_space_state
	_snap_to_road_once()                  # one hard snap at start

func _physics_process(delta: float) -> void:
	# Steering (A/D)
	var steer_input = Input.get_axis("right", "left")
	steering = lerp(steering, steer_input * 0.4, 5 * delta)

	# Acceleration (W/S)
	var acceleration = Input.get_axis("down", "up")

	var rpm = $Rear_Left.get_rpm()
	$Rear_Left.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)

	rpm = $Rear_Right.get_rpm()
	$Rear_Right.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)

	# ---- brute-force safety net ----
	_resnap_if_falling()
	_clamp_below_world()

# ---------- safety helpers ----------
func _resnap_if_falling() -> void:
	# If we’re clearly falling and can see the road under us, teleport back to it.
	if linear_velocity.y <= FALL_SPEED_Y:
		_fall_counter += 1
	else:
		_fall_counter = 0

	if _fall_counter >= FALL_FRAMES:
		var hit := _ground_hit_at(global_transform.origin + Vector3.UP * 2.0)
		if not hit.is_empty():
			_snap_to_hit(hit)
			# cancel vertical motion so we don't immediately fall again
			linear_velocity.y = 0.0
			angular_velocity  = Vector3.ZERO
			_fall_counter = 0

func _clamp_below_world() -> void:
	# Absolute last-ditch guard: if we ever get yeeted below the world, bounce back up.
	if global_transform.origin.y < SAFE_FLOOR_Y:
		var hit := _ground_hit_at(Vector3(global_transform.origin.x, SAFE_FLOOR_Y + 100.0, global_transform.origin.z))
		if not hit.is_empty():
			_snap_to_hit(hit)
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			_fall_counter = 0

func _snap_to_road_once() -> void:
	if _snapped_once:
		return
	var hit := _ground_hit_at(global_transform.origin + Vector3.UP * 5.0)
	if not hit.is_empty():
		_snap_to_hit(hit)
		_snapped_once = true
	else:
		push_warning("Brute snap: no road found under car. Check road layer bit = %d" % ROAD_LAYER_BIT)

func _ground_hit_at(from_pos: Vector3) -> Dictionary:
	var from := from_pos
	var to   := from_pos + Vector3.DOWN * PROBE_LEN
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1 << (ROAD_LAYER_BIT - 1)
	return _dss.intersect_ray(q)

func _snap_to_hit(hit: Dictionary) -> void:
	var t := global_transform
	t.origin.y = (hit["position"] as Vector3).y + SNAP_OFFSET
	global_transform = t
