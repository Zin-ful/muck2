extends StaticBody3D

@export var type: String
@export var value: int
@export var hold_size: float = 0.2
@onready var aplay: AnimationPlayer = $AnimationPlayer
var can_use: bool = true

func use():
	if can_use:
		can_use = false
		aplay.play("eat")
		return [type, value]
	else:
		return ["empty", 0]

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	can_use = true
