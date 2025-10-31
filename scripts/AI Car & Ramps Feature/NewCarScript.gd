extends VehicleBody3D


@export var max_engine_force := 1200.0
@export var max_steer := 0.6
@export var brake_force := 25.0

func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("down", "up")
	var steer := Input.get_axis("right", "left")
	
	engine_force = throttle * max_engine_force
	steering = lerp(steering, steer * max_steer, 8.0 * delta)
	
	if Input.is_action_pressed("brake"):
		brake = brake_force
	else:
		brake = 0.0
		
func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
