extends StaticBody3D


@onready var animation_player: AnimationPlayer = $Mesh/AnimationPlayer
@onready var health_bar: TextureProgressBar = $SubViewport/TextureProgressBar
@onready var timer: Timer = $Timer
@export var health = 20
@export var req_level: int = 0
@export var hold_size: float = 0.2
@export var slot_data: SlotData
@onready var sprite_3d: Sprite3D = $Sprite3D

signal drop_items(pos: Vector3, slot: SlotData)
var player = null


func _ready() -> void:
	sprite_3d.no_depth_test = true
	sprite_3d.render_priority = 1
	health_bar.max_value = health
	health_bar.value = health
	timer.one_shot = true
	sprite_3d.visible = false
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	if sprite_3d.visible:
		var look_target = player.global_transform.origin
		look_target.y = sprite_3d.global_transform.origin.y
		sprite_3d.look_at(look_target, Vector3.UP)

func damage(damage: int, obj_level: int):
	sprite_3d.visible = true
	timer.wait_time = 5.0
	timer.start()
	if obj_level < req_level:
		return
	animation_player.play("on_hit")
	health -= damage
	health_bar.value = health
	if health < 1:
		drop_items.emit(global_transform.origin, slot_data)
		destroy()

func destroy():
	queue_free()

func _on_detection_area_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("get_damage_info"):
		damage(body.get_damage(), body.get_level())

func set_hold_size() -> void:
	self.scale = Vector3(hold_size, hold_size, hold_size)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	pass

func _on_timer_timeout() -> void:
	sprite_3d.visible = false
	
func use() -> Array:
	return ["empty", 0]
