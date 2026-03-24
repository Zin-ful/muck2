extends Control
@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var current_slot: PanelContainer = $CurrentSlot

var grabbed_slot: SlotData

func _physics_process(delta: float) -> void:
	if current_slot.visible:
		current_slot.global_position = get_global_mouse_position() + Vector2(5, 5)

func set_player_inventory_data(inventory_data: InventoryData):
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int):
	match [grabbed_slot, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot = inventory_data.grab_slot(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot = inventory_data.drop_slot(grabbed_slot, index)
	update_grabbed_slot()

func update_grabbed_slot():
	if grabbed_slot:
		current_slot.show()
		current_slot.set_slot_data(grabbed_slot)
	else:
		current_slot.hide()
