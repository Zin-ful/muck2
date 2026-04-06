@tool
extends StaticBody3D

@export var hold_size: float = 0.2
@export var type: String
@export var value: int
@export var level: int = 0
@export var slot_data: SlotData
@export var can_be_picked_up: bool = true
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var aplay: AnimationPlayer = $AnimationPlayer

#press E shows up when in hand

func _ready() -> void:
	if can_be_picked_up:
		collision_shape_3d.disabled = false
		set_hold_size()
	else:
		self.set_collision_layer_value(3, false)
		collision_shape_3d.disabled = true

func use():
	collision_shape_3d.disabled = false
	aplay.play("hit")
	print("using rock")
	return [type, value]
	
func get_damage():
	return value

func get_level():
	return level


func get_damage_info():
	pass

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("done")
	collision_shape_3d.disabled = true
	
func pickup(inventory_data):
	self.set_collision_layer_value(3, false)
	collision_shape_3d.disabled = true
	print("rock pickup")
	if inventory_data.pick_up_slot_data(slot_data):
		queue_free()
		
