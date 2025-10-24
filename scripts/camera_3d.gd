extends Camera3D

@export var track: Path3D
func _ready():
	make_current()
	if track:
		var p := track.curve.sample_baked(0.0)
		global_position = p + Vector3(0, 15, -30)
		look_at(p, Vector3.UP)
