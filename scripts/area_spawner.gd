extends Node3D

@export var zone_size := Vector3(20.0, 1.0, 20.0)   # XZ defines area, Y is visual only
@export var ray_origin_height := 50.0                # how high above zone origin rays fire from
@export var ray_reach_depth := 100.0                 # how far down the ray travels

@export_group("Objects")
@export var spawn_scenes: Array[PackedScene]
@export var spawn_count := 50
@export_range(0.0, 1.0) var max_slope := 0.4

@export_group("Scatter Settings")
@export var random_seed := 42
@export var random_scale_variation := 0.3
@export var align_to_normal := true
@export var y_offset := 0.2                          # lift off surface slightly

var _rng := RandomNumberGenerator.new()


func spawn_all() -> void:
	_rng.seed = random_seed
	var placed := 0
	var attempts := 0
	var max_attempts := spawn_count * 20
	var half_x := zone_size.x / 2.0
	var half_z := zone_size.z / 2.0
	while placed < spawn_count and attempts < max_attempts:
		
		attempts += 1

		# Random point within the zone's local XZ footprint
		var local_x := _rng.randf_range(-half_x, half_x)
		var local_z := _rng.randf_range(-half_z, half_z)

		# Convert to world space so the zone node can be placed/rotated anywhere
		var world_pos := global_transform * Vector3(local_x, 0.0, local_z)

		var hit := _raycast_down(world_pos)
		if hit.is_empty():
			continue
		var surface_pos: Vector3 = hit.position
		var normal: Vector3 = hit.normal
		var slope := 1.0 - normal.y
		if slope > max_slope:
			continue

		var scene := spawn_scenes[_rng.randi() % spawn_scenes.size()]
		_place_object(scene, surface_pos, normal)
		placed += 1

func _raycast_down(world_xz: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var origin := Vector3(world_xz.x, world_xz.y + ray_origin_height, world_xz.z)
	var target := Vector3(world_xz.x, world_xz.y - ray_reach_depth, world_xz.z)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	# Optional: exclude the spawner itself if it has a collider
	query.exclude = [self]
	return space.intersect_ray(query)


func _place_object(scene: PackedScene, pos: Vector3, surface_normal: Vector3) -> void:
	var instance := scene.instantiate() as Node3D
	add_child(instance)

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


# --- Editor visualization ---
# Draws a wire box in the editor so you can see the spawn zone without a mesh node.
func _get_configuration_warnings() -> PackedStringArray:
	if spawn_scenes.is_empty():
		return ["No spawn_scenes assigned."]
	return []
