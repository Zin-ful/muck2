extends StaticBody3D

@export var health = 50
@export var hold_size: float = 0.2
var atk = 6
signal drop_items(pos: Vector3)

func get_damage():
	return atk

func get_damage_info():
	pass

func damage(damage: int):
	health -= damage
	print("taking damage")
	if health < 1:
		print("emitting drop")
		drop_items.emit(global_transform.origin)
		destroy()

func destroy():
	print("destroying")
	queue_free()

func _on_detection_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	print("MY ASSSS NOO STAY AAWYAYAYAYA")
	if body.has_method("get_damage_info"):
		damage(body.get_damage())

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)
