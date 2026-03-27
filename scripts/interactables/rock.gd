extends StaticBody3D

@export var health = 50
signal drop_items(pos: Vector3)

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
	pass # Replace with function body.
