extends StaticBody3D

@export var health = 50
@export var hold_size: float = 0.2
@export var slot_data: SlotData
@onready var animation_player: AnimationPlayer = $rock_mesh/AnimationPlayer

signal drop_items(pos: Vector3, slot: SlotData)

func damage(damage: int):
	animation_player.play("on_hit")
	health -= damage
	print("taking damage")
	if health < 1:
		print("emitting drop")
		drop_items.emit(global_transform.origin, slot_data)
		destroy()

func destroy():
	print("destroying")
	queue_free()

func _on_detection_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	print("ow")
	if body.has_method("get_damage_info"):
		damage(body.get_damage())

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("done")
