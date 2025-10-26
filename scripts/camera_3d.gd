extends Camera3D

## Assign Bilal's Path3D here in the Inspector
@export var track: Path3D

## Mode: 0 = Top-down (orthographic), 1 = Chase (perspective)
@export var mode: int = 0

## Top-down settings
@export var top_height: float = 150.0      # how high above the track (Y)
@export var top_margin: float = 20.0       # extra padding around the track
@export var auto_fit: bool = true          # auto fit orthographic size to the track

## Chase settings (if you ever switch to mode = 1)
@export var chase_height: float = 15.0
@export var chase_distance: float = 30.0
@export var smooth: float = 8.0            # camera smoothing for chase
@export var follow_t: float = 0.0          # 0..1 along the path (for testing)

func _ready() -> void:
	make_current()
	if track:
		var p := track.curve.sample_baked(0.0)
		global_position = p + Vector3(0, 150, 0)
		look_at(p, Vector3.FORWARD)

func _physics_process(delta: float) -> void:
	if not track: return
	if mode == 1:
		_update_chase(delta)

# ----------------- Top-down orthographic -----------------
func _setup_top_down() -> void:
	projection = PROJECTION_ORTHOGONAL
	rotation_degrees = Vector3(-90, 0, 0)      # look straight down
	# center over the curve and size to fit
	var center_and_radius := _curve_bounds_xz(track.curve)
	var center: Vector3 = center_and_radius[0]
	var radius: float    = center_and_radius[1]
	global_position = Vector3(center.x, top_height, center.z)
	if auto_fit:
		# Orthographic 'size' is half-height of the view volume;
		# cover the larger of X/Z extents with a margin.
		size = radius + top_margin

func _curve_bounds_xz(curve: Curve3D) -> Array:
	var len : float = max(curve.get_baked_length(), 0.1)
	var step := 1.0                               # 1m sampling is fine
	var minx := INF; var maxx := -INF
	var minz := INF; var maxz := -INF
	var d := 0.0
	while d <= len + 0.001:
		var p := curve.sample_baked(d)
		minx = min(minx, p.x); maxx = max(maxx, p.x)
		minz = min(minz, p.z); maxz = max(maxz, p.z)
		d += step
	var center := Vector3((minx + maxx) * 0.5, 0.0, (minz + maxz) * 0.5)
	var radius : float = max(maxx - minx, maxz - minz) * 0.5
	return [center, radius]

# ----------------- Chase (optional) -----------------
func _setup_chase() -> void:
	projection = PROJECTION_PERSPECTIVE
	rotation_degrees = Vector3.ZERO
	_update_chase(0.0)  # place once

func _update_chase(delta: float) -> void:
	var c := track.curve
	var L : float = max(c.get_baked_length(), 0.1)
	var s : float = clamp(follow_t, 0.0, 1.0) * L
	var p := c.sample_baked(s)
	var p2 := c.sample_baked(min(s + 0.5, L))   # forward sample
	var fwd := (p2 - p).normalized()
	var desired := p - fwd * chase_distance + Vector3(0, chase_height, 0)

	# smooth move
	var k := 1.0 - pow(0.001, delta * smooth)
	global_position = global_position.lerp(desired, k)
	look_at(p, Vector3.UP)
