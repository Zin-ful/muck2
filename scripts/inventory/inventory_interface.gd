extends Control
@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var current_slot: PanelContainer = $CurrentSlot
@onready var external_inventory: PanelContainer = $ExternalInventory

signal drop_slot_data(slot_data:SlotData)

var grabbed_slot: SlotData

var external_owner: InventoryData

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
		[null, MOUSE_BUTTON_RIGHT]:
			pass
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot = inventory_data.drop_single_slot(grabbed_slot, index)
	
	update_grabbed_slot()

func update_grabbed_slot():
	if grabbed_slot:
		current_slot.show()
		current_slot.set_slot_data(grabbed_slot)
	else:
		current_slot.hide()

func set_external_inventory(owner):
	var inventory_data = owner.inventory_data
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot)
				grabbed_slot = null
			MOUSE_BUTTON_RIGHT:
				var new_slot = grabbed_slot.duplicate()
				new_slot.quantity = 1
				grabbed_slot.quantity -= 1
				drop_slot_data.emit(new_slot)
				if grabbed_slot.quantity < 1:
					grabbed_slot = null
				
		update_grabbed_slot()

func _on_inventory_interface_visibility_changed() -> void:
	if not visible and grabbed_slot:
		drop_slot_data.emit(grabbed_slot)
		grabbed_slot = null
		update_grabbed_slot()

func set_hotbar_data(hotbar_data: HotBarData, hotbar_node: PanelContainer):
	hotbar_data.inventory_interact.connect(on_inventory_interact)
	hotbar_node.set_hotbar_data(hotbar_data)
	
