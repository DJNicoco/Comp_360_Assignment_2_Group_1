@tool
extends Node3D
class_name RoadBuilder

# ---------- Public knobs ----------
@export_node_path("Path3D") var path: NodePath        # Leave empty to auto-find ../Track or first Path3D in scene

@export var half_width: float = 2.5 : set = _set_half_width
@export var step: float = 0.5 : set = _set_step
@export var uv_repeat_meters: float = 4.0 : set = _set_uv_repeat
@export var hard_normals_up: bool = true : set = _set_hard_normals_up
@export var auto_rebuild: bool = true : set = _set_auto_rebuild

@export_flags_3d_physics var road_layer := 1
@export_flags_3d_physics var road_mask := 1

# ---------- One-click action in Inspector ----------
@export_category("Actions")
@export var Rebuild: bool:
	set(v):
		if v:
			rebuild()
			set_deferred("Rebuild", false)

# ---------- Cached children ----------
var _mesh_instance: MeshInstance3D
var _static_body: StaticBody3D
var _collision_shape: CollisionShape3D

# ---------- Lifecycle ----------
func _ready() -> void:
	_ensure_children()
	if Engine.is_editor_hint():
		if auto_rebuild: rebuild()
	else:
		rebuild()

func _notification(what):
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_ENTER_TREE:
		_ensure_children()

# ---------- Rebuild-on-change setters ----------
func _maybe_rebuild():
	if Engine.is_editor_hint() and auto_rebuild:
		rebuild()

func _set_half_width(v: float) -> void:
	half_width = v
	_maybe_rebuild()

func _set_step(v: float) -> void:
	step = v
	_maybe_rebuild()

func _set_uv_repeat(v: float) -> void:
	uv_repeat_meters = v
	_maybe_rebuild()

func _set_hard_normals_up(v: bool) -> void:
	hard_normals_up = v
	_maybe_rebuild()

func _set_auto_rebuild(v: bool) -> void:
	auto_rebuild = v

func _own(n: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var root := get_tree().edited_scene_root
	if root == null:
		root = self
	n.owner = root

# ---------- Ensure child nodes exist ----------
func _ensure_children() -> void:
	_mesh_instance = get_node_or_null("Mesh") as MeshInstance3D
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "Mesh"
		add_child(_mesh_instance)
		_own(_mesh_instance)

	_static_body = get_node_or_null("StaticBody3D") as StaticBody3D
	if _static_body == null:
		_static_body = StaticBody3D.new()
		_static_body.name = "StaticBody3D"
		add_child(_static_body)
		_own(_static_body)

	_collision_shape = _static_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape == null:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		_static_body.add_child(_collision_shape)
		_own(_collision_shape)

	_static_body.collision_layer = road_layer
	_static_body.collision_mask  = road_mask

	if Engine.is_editor_hint():
		var names := PackedStringArray()
		for c in get_children():
			names.push_back(c.name)
		push_warning("RB ensure: children=%d [%s]" % [get_child_count(), ",".join(names)])
		if _mesh_instance:       push_warning("  Mesh owner: %s" % [str(_mesh_instance.owner)])
		if _static_body:         push_warning("  StaticBody3D owner: %s" % [str(_static_body.owner)])
		if _collision_shape:     push_warning("  CollisionShape3D owner: %s" % [str(_collision_shape.owner)])

# ---------- Public build ----------
func rebuild() -> void:
	_ensure_children()
	
	var p := _get_path3d()
	if p == null:
		push_error("RoadBuilder: No Path3D found. (Assign 'path' or add a sibling named 'Track')")
		return

	var curve := p.curve
	if curve == null or curve.get_point_count() < 2:
		push_error("RoadBuilder: Path3D curve needs at least 2 points.")
		return

	var mesh := _build_mesh(curve)
	if mesh.get_surface_count() == 0:
		push_error("RoadBuilder: Mesh generation failed (check curve spacing/step).")
		return

	_mount_mesh(mesh)
	_make_collision(mesh)
	
	push_warning("RoadBuilder: Rebuilt mesh + collision.")

# ---------- Find Path3D ----------
func _get_path3d() -> Path3D:
	var p := get_node_or_null(path) as Path3D
	if p != null:
		return p
	var sib := get_node_or_null("../Track")
	if sib is Path3D:
		return sib as Path3D
	var root := get_tree().current_scene
	if root:
		return _find_path3d_recursive(root)
	return null

func _find_path3d_recursive(n: Node) -> Path3D:
	if n is Path3D:
		return n as Path3D
	for c in n.get_children():
		var hit := _find_path3d_recursive(c)
		if hit:
			return hit
	return null

# ---------- Mesh builder ----------
func _build_mesh(curve: Curve3D) -> ArrayMesh:
	var length: float = curve.get_baked_length()
	var is_closed: bool = curve.is_closed()

	var verts := PackedVector3Array()
	var uvs   := PackedVector2Array()
	var inds  := PackedInt32Array()

	if length <= 0.05:
		verts = PackedVector3Array([Vector3(-2,0,0), Vector3(2,0,0), Vector3(-2,0,10), Vector3(2,0,10)])
		uvs   = PackedVector2Array([Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)])
		inds  = PackedInt32Array([0,1,3, 0,3,2])
	else:
		if step >= length * 0.5:
			step = max(0.25, length * 0.1)

		var dist: float = 0.0
		var v_i: int = 0

		while dist <= length + 0.001:
			var pt: Vector3 = curve.sample_baked(dist)

			var next_dist: float = dist + max(step, 0.1)
			if next_dist > length:
				next_dist = 0.0 if is_closed else length

			var fwd: Vector3 = curve.sample_baked(next_dist) - pt
			if fwd.length_squared() < 1e-6:
				fwd = Vector3.FORWARD

			var right: Vector3 = fwd.normalized().cross(Vector3.UP).normalized()
			var side: Vector3 = right * half_width

			var left_pt: Vector3  = pt - side
			var right_pt: Vector3 = pt + side

			verts.push_back(left_pt)
			verts.push_back(right_pt)

			var vcoord: float = dist / max(uv_repeat_meters, 0.001)
			uvs.push_back(Vector2(vcoord, 0.0))
			uvs.push_back(Vector2(vcoord, 1.0))

			if v_i >= 2:
				inds.append_array([v_i - 2, v_i - 1, v_i + 1,  v_i - 2, v_i + 1, v_i])

			v_i += 2
			dist += step

		if is_closed and v_i >= 4:
			inds.append_array([v_i - 2, v_i - 1, 1,  v_i - 2, 1, 0])

	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for j in range(normals.size()):
		normals[j] = Vector3.UP if hard_normals_up else Vector3.UP

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX]  = inds
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh := ArrayMesh.new()
	if verts.size() > 0 and inds.size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# ---------- Mount mesh + material ----------
func _mount_mesh(m: ArrayMesh) -> void:
	_mesh_instance.mesh = m

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://textures/Road.png")
	mat.albedo_color = Color(1.4, 1.4, 1.4)
	mat.uv1_scale = Vector3(1, 3, 1)
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.set_surface_override_material(0, mat)

# ---------- Build collision ----------
func _make_collision(m: ArrayMesh) -> void:
	if m.get_surface_count() == 0:
		return

	# Build faces in local space
	var arrays := m.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var inds:  PackedInt32Array    = arrays[Mesh.ARRAY_INDEX]

	var faces := PackedVector3Array()
	faces.resize(inds.size())
	for i in range(inds.size()):
		faces[i] = verts[inds[i]]

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)

	_collision_shape.disabled = false
	_collision_shape.shape = shape

	# Put the StaticBody exactly where the visible mesh is
	_static_body.top_level = true
	_static_body.global_transform = global_transform

	# **Force** a known layer/mask = 1 for the road
	_static_body.collision_layer = 0
	_static_body.collision_mask  = 0
	_static_body.set_collision_layer_value(1, true)
	_static_body.set_collision_mask_value(1, true)

	# Debug: prove the collider is alive & on layer 1
	print("ROAD collider faces=", faces.size(),
		  " layer=", _static_body.collision_layer,
		  " mask=", _static_body.collision_mask)
