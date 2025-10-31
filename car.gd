extends VehicleBody3D

var max_rpm = 500
var max_torque = 200

func _physics_process(delta):
	# Steering (A/D)
	var steer_input = Input.get_axis("right", "left")
	steering = lerp(steering, steer_input * 0.4, 5 * delta)

	# Acceleration (W/S)
	var acceleration = Input.get_axis("down", "up")

	var rpm = $back_left_wheel.get_rpm()
	$back_left_wheel.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)

	rpm = $back_right_wheel.get_rpm()
	$back_right_wheel.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
