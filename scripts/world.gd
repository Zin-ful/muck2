extends Node3D

const PickUp = preload("uid://bqtjsbrtf0mv5")
@onready var player: CharacterBody3D = $Player
@onready var terrain: MeshInstance3D = $Terrain
@onready var spawner: Node3D = $TerrainGenerator

var inventory_interface: Control

func _ready():
	inventory_interface = player.inventory_interface
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_hotbar_data(player.hotbar_data, player.hot_bar)
	inventory_interface.drop_slot_data.connect(_on_inventory_interface_drop_slot_data)
	get_tree().node_added.connect(_on_node_added)
	spawner.call_deferred("spawn_all")

func _on_node_added(node: Node) -> void:
	if node.has_signal("drop_items"):
		node.drop_items.connect(_on_drop_items)


func _on_inventory_interface_drop_slot_data(slot_data) -> void:
	print("dropping item")
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.global_transform = player.get_current_transform()
	add_child(pick_up)
	
func _on_drop_items(pos: Vector3, slot: SlotData) -> void:
	print("dropping item")
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot
	pick_up.global_transform = player.get_current_transform()
	add_child(pick_up)
