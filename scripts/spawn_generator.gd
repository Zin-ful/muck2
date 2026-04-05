extends Node3D

@export var terrain: MeshInstance3D  #terrain node for access
@export_group("Spawn Areas")
@export var spawn_scenes: Array[PackedScene]
@export var spawn_scenes_count := 200
@export_range(0.0, 1.0) var spawn_max_slope := 0.3

@export_group("Chests")
@export var chests_scenes: Array[PackedScene]
@export var chests_count := 150
@export_range(0.0, 1.0) var chests_min_height_ratio := 0.0
@export_range(0.0, 1.0) var chests_max_height_ratio := 1.0
@export_range(0.0, 1.0) var chests_max_slope := 0.7           #chests can be on steeper terrain

@export_group("Rocks")
@export var rocks_scenes: Array[PackedScene]
@export var rocks_count := 150
@export_range(0.0, 1.0) var rocks_min_height_ratio := 0.0
@export_range(0.0, 1.0) var rocks_max_height_ratio := 1.0
@export_range(0.0, 1.0) var rocks_max_slope := 0.7 

@export_group("Grass")
@export var grass_mesh: Mesh
@export var grass_count := 300000
@export var grass_noise: FastNoiseLite
@export_range(0.0, 1.0) var grass_noise_threshold := 0.3 
@export_range(0.0, 1.0) var grass_min_height_ratio := 0.0
@export_range(0.0, 1.0) var grass_max_height_ratio := 0.6
@export_range(0.0, 1.0) var grass_max_slope := 0.25

@export_group("Scatter Settings")
@export var random_seed := randi() % 500000000
@export var random_scale_variation := 0.3 
@export var align_to_normal := true

var _rng := RandomNumberGenerator.new()

func spawn_all() -> void:
	var seed = randi() % 500000000
	print("SpawnGenerator: Seed | Grass = ", seed)
	grass_noise.seed = seed
	_rng.seed = random_seed
	print("SpawnGenerator: Seed | All Other Objects = ", seed)
	if not terrain:
		push_error("TerrainObjectSpawner: no terrain assigned")
		return
	if not terrain.noise:
		push_error("Terrain has no noise assigned"); return
	_spawn_areas(spawn_scenes, spawn_scenes_count)
	_spawn_objects(chests_scenes, chests_count, chests_min_height_ratio, chests_max_height_ratio, chests_max_slope, false)
	_spawn_objects(rocks_scenes, rocks_count, rocks_min_height_ratio, rocks_max_height_ratio, rocks_max_slope, false)
	_spawn_grass()
	
func _spawn_grass() -> void:
	if not grass_mesh:
		push_error("No grass mesh assigned"); return

	var half: float = terrain.size / 2.0
	var min_h: float = -terrain.height + terrain.height * grass_min_height_ratio * 2.0
	var max_h: float = -terrain.height + terrain.height * grass_max_height_ratio * 2.0

	# Collect valid transforms first
	var transforms: Array[Transform3D] = []
	var attempts := 0
	var max_attempts := grass_count * 20

	while transforms.size() < grass_count and attempts < max_attempts:
		attempts += 1
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)

		# Cheap noise check BEFORE the expensive raycast
		if grass_noise:
			var noise_val := grass_noise.get_noise_2d(x, z)  # returns -1.0 to 1.0
			if noise_val < grass_noise_threshold:
				continue

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

		# Build transform aligned to surface normal
		var scale_factor := 1.0 + _rng.randf_range(-random_scale_variation, random_scale_variation)
		var random_y_rot := _rng.randf_range(0.0, TAU)
		var up := normal
		var forward := Vector3.FORWARD.rotated(Vector3.UP, random_y_rot)
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.RIGHT
		var right := forward.cross(up).normalized()
		forward = up.cross(right).normalized()

		var basis := Basis(right, up, -forward).scaled(Vector3.ONE * scale_factor)
		var t := Transform3D(basis, Vector3(x, y + 0.2, z))
		transforms.append(t)

	# Build the MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = transforms.size()
	mm.mesh = grass_mesh

	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

func _spawn_areas(scenes: Array[PackedScene], count: int):
	if not scenes:
		return
	print("SpawnGenerator > Areas: terrain.size = ", terrain.size, " | half = ", terrain.size / 2.0)
	var half: float = terrain.size / 2.0
	var placed := 0
	var attempts := 0
	var max_attempts := count * 20
	print("SpawnGenerator > Areas: spawning areas")
	while placed < count and attempts < max_attempts:
		attempts += 1
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)
		var hit := _get_surface_height(x, z)
		if hit.is_empty():
			continue
		var y: float = hit.position.y
		var normal: Vector3 = hit.normal
		
		if placed == 0:
			print("SpawnGenerator > Areas: Sample point: x=", x, " z=", z)
			print("SpawnGenerator > Areas: get_height returned: ", y)
			print("SpawnGenerator > Areas: terrain global_pos: ", terrain.global_position)
			print("SpawnGenerator > Areas: normal: ", normal)

		var scene := scenes[_rng.randi() % scenes.size()]
		_place_object(scene, Vector3(x, y, z), normal, 0.5, true)
		placed += 1
	print("SpawnGenerator > Areas: %d attempts, %d placed" % [attempts, placed])

func _spawn_objects(
	scenes: Array[PackedScene],
	count: int,
	min_height_ratio: float,
	max_height_ratio: float,
	max_slope: float,
	rng: bool
) -> void:
	if not scenes:
		return
	print("SpawnGenerator > Objects: terrain.size = ", terrain.size, " | half = ", terrain.size / 2.0)
	var half: float = terrain.size / 2.0
	var min_h: float = -terrain.height + terrain.height * min_height_ratio * 2.0
	var max_h: float = -terrain.height + terrain.height * max_height_ratio * 2.0
	var placed := 0
	var attempts := 0
	var max_attempts := count * 20 

	while placed < count and attempts < max_attempts:
		attempts += 1
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)
		var hit := _get_surface_height(x, z)
		if hit.is_empty():
			continue
		var y: float = hit.position.y
		var normal: Vector3 = hit.normal
		
		if placed == 0:
			print("SpawnGenerator > Objects: Sample point: x=", x, " z=", z)
			print("SpawnGenerator > Objects: get_height returned: ", y)
			print("SpawnGenerator > Objects: terrain global_pos: ", terrain.global_position)
			print("SpawnGenerator > Objects: normal: ", normal)
		
		if y < min_h or y > max_h:
			continue

		var slope: float = 1.0 - normal.y
		if slope > max_slope:
			continue
		var scene := scenes[_rng.randi() % scenes.size()]
		_place_object(scene, Vector3(x, y, z), normal, 0.5, rng)
		placed += 1

func _place_object(scene: PackedScene, pos: Vector3, surface_normal: Vector3, y_offset: float, rng: bool) -> void:
	var instance := scene.instantiate() as Node3D
	add_child(instance)
	if rng:
		var scale_factor := 1.0 + _rng.randf_range(-random_scale_variation, random_scale_variation)
		instance.scale = Vector3.ONE * scale_factor

	var random_y_rot := _rng.randf_range(0.0, TAU)
	if align_to_normal:
		var up := surface_normal
		var forward := Vector3.FORWARD.rotated(Vector3.UP, random_y_rot)
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.RIGHT.rotated(Vector3.UP, random_y_rot)
		var right := forward.cross(up).normalized()
		forward = up.cross(right).normalized()
		instance.global_transform.basis = Basis(right, up, -forward) * instance.global_transform.basis
	else:
		instance.rotation.y = random_y_rot

	instance.global_position = pos + surface_normal * y_offset
	if instance is Node3D and instance.has_method("spawn_all"):
		instance.spawn_all()

func _get_surface_height(x: float, z: float) -> Dictionary:
	var space := terrain.get_world_3d().direct_space_state
	var origin := Vector3(x, terrain.height + 10.0, z)
	var target := Vector3(x, -terrain.height - 10.0, z)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	var result := space.intersect_ray(query)
	return result
