extends Camera3D

@export var target: NodePath
@export var follow_distance: float = 8.0
@export var height: float = 3.0
@export var smooth_speed: float = 5.0
@export var tilt_strength: float = 0.4 

var _target_node: Node3D
var _last_target_pos: Vector3

func _ready():
	if target != null:
		_target_node = get_node(target)
	if _target_node:
		_last_target_pos = _target_node.global_transform.origin

func _process(delta):
	if _target_node == null:
		return

	var target_pos = _target_node.global_transform.origin
	var desired_pos = target_pos - _target_node.global_transform.basis.z * follow_distance
	desired_pos.y += height
	
	global_transform.origin = global_transform.origin.lerp(desired_pos, delta * smooth_speed)

	look_at(target_pos, Vector3.UP)

	var car_velocity = (_target_node.global_transform.origin - _last_target_pos) / delta
	var sideways_speed = _target_node.global_transform.basis.x.dot(car_velocity)
	
	var roll_tilt = clamp(-sideways_speed * tilt_strength, -10.0, 10.0)
	
	var basis = global_transform.basis
	basis = basis.rotated(basis.z.normalized(), deg_to_rad(roll_tilt))
	global_transform.basis = basis.orthonormalized()
	
	_last_target_pos = _target_node.global_transform.origin
