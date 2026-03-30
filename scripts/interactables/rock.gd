extends StaticBody3D

@export var hold_size: float = 0.2
var atk = 6
@export var type: String
@export var value: int
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var aplay: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	collision_shape_3d.disabled = true

func use():
	collision_shape_3d.disabled = false
	aplay.play("hit")
	print("using rock")
	return [type, value]
	
	
func get_damage():
	return atk

func get_damage_info():
	pass

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("done")
	collision_shape_3d.disabled = true
