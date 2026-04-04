extends Node3D

@export var terrain: MeshInstance3D
@export_group("Grass")
@export var grass_mesh: Mesh                  # your quad/blade mesh
@export var grass_count := 5000
@export_range(0.0, 1.0) var grass_min_height_ratio := 0.0
@export_range(0.0, 1.0) var grass_max_height_ratio := 0.6   # no grass on peaks
@export_range(0.0, 1.0) var grass_max_slope := 0.35         # flat-ish ground only
@export_group("Scatter Settings")
@export var random_seed := 42
@export var random_scale_variation := 0.2
@export var use_multimesh := true

var _rng := RandomNumberGenerator.new()

func spawn_all() -> void:
	if not terrain or not terrain.noise:
		push_error("GrassSpawner: terrain or noise missing")
		return
	_rng.seed = random_seed
	if use_multimesh:
		_spawn_grass_multimesh()
	else:
		_spawn_grass_instances()  # only use for very low counts

func _spawn_grass_multimesh() -> void:
	var half: float = terrain.size / 2.0
	var min_h: float = -terrain.height + terrain.height * grass_min_height_ratio * 2.0
	var max_h: float = -terrain.height + terrain.height * grass_max_height_ratio * 2.0

	var transforms: Array[Transform3D] = []
	var attempts := 0
	var max_attempts := grass_count * 10

	while transforms.size() < grass_count and attempts < max_attempts:
		attempts += 1
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)

		# Use raycast just like your tree/rock spawners
		var hit := _get_surface_height(x, z)
		if hit.is_empty():
			continue

		var y: float = hit.position.y
		var normal: Vector3 = hit.normal

		if y < min_h or y > max_h:
			continue
		var slope := 1.0 - normal.y
		if slope > grass_max_slope:
			continue

		transforms.append(_make_transform(Vector3(x, y, z), normal))

	# rest of multimesh building stays the same...
func _make_transform(pos: Vector3, surface_normal: Vector3) -> Transform3D:
	var scale_factor := 1.0 + _rng.randf_range(-random_scale_variation, random_scale_variation)
	var random_y_rot := _rng.randf_range(0.0, TAU)

	var up := surface_normal
	var forward := Vector3.FORWARD.rotated(Vector3.UP, random_y_rot)
	if abs(up.dot(forward)) > 0.99:
		forward = Vector3.RIGHT.rotated(Vector3.UP, random_y_rot)
	var right := forward.cross(up).normalized()
	forward = up.cross(right).normalized()

	var basis := Basis(right, up, -forward).scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, pos)

# Fallback for very low grass counts (< ~200)
func _spawn_grass_instances() -> void:
	var half: float = terrain.size / 2.0
	var min_h: float = -terrain.height + terrain.height * grass_min_height_ratio * 2.0
	var max_h: float = -terrain.height + terrain.height * grass_max_height_ratio * 2.0

	for _i in grass_count:
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)
		var y: float = terrain.get_height(x, z)
		var normal: Vector3 = terrain.get_normal(x, z)

		if y < min_h or y > max_h:
			continue
		var slope := 1.0 - normal.y
		if slope > grass_max_slope:
			continue

		var instance := MeshInstance3D.new()
		instance.mesh = grass_mesh
		add_child(instance)
		instance.global_transform = _make_transform(Vector3(x, y, z), normal)

func _get_surface_height(x: float, z: float) -> Dictionary:
	var space := terrain.get_world_3d().direct_space_state
	var origin := Vector3(x, terrain.height + 10.0, z)
	var target := Vector3(x, -terrain.height - 10.0, z)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	var result := space.intersect_ray(query)
	return result
