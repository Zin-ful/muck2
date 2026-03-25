extends RigidBody3D

@export var slot_data: SlotData
@onready var object_mesh: MeshInstance3D = $ObjectMesh
@onready var detection_area: Area3D = $DetectionArea
@export var SCALE: float = 1

func _ready() -> void:
	object_mesh.mesh = slot_data.item_data.mesh
	var collision_shape = object_mesh.mesh.create_convex_shape()
	var physical_collision = CollisionShape3D.new()
	var detection_collision = CollisionShape3D.new()
	physical_collision.shape = collision_shape
	detection_collision.shape = collision_shape
	$".".add_child(physical_collision)
	detection_area.add_child(detection_collision)
	self.scale = Vector3(SCALE, SCALE, SCALE)
	
	
func _physics_process(delta: float) -> void:
	object_mesh.rotate_y(delta)


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
