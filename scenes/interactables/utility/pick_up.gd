extends RigidBody3D

@export var slot_data: SlotData
@onready var sprite: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	sprite.mesh = slot_data.item_data.mesh

func _physics_process(delta: float) -> void:
	sprite.rotate_y(delta)


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
