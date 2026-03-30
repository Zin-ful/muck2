extends PanelContainer

const Slot = preload("uid://cscglddjwgx7y")  # same Slot scene you already use

signal hotbar_edited()

var hotbar_data: HotBarData
var slot_nodes: Array = []

func set_hotbar_data(data: HotBarData) -> void:
	if hotbar_data:
		if hotbar_data.inventory_updated.is_connected(populate_slots):
			hotbar_data.inventory_updated.disconnect(populate_slots)
		if hotbar_data.hotbar_selection_changed.is_connected(update_selection_highlight):
			hotbar_data.hotbar_selection_changed.disconnect(update_selection_highlight)

	hotbar_data = data
	hotbar_data.inventory_updated.connect(populate_slots)
	hotbar_data.hotbar_selection_changed.connect(update_selection_highlight)
	populate_slots(hotbar_data)

func populate_slots(data: InventoryData) -> void:
	print("populate_slots called with ", data.slot_datas.size(), " slots")
	
	for child in $MarginContainer/ItemGrid.get_children():
		child.queue_free()
	slot_nodes.clear()

	for i in data.slot_datas.size():
		var slot = Slot.instantiate()
		$MarginContainer/ItemGrid.add_child(slot)
		slot.slot_clicked.connect(data.on_slot_clicked)
		slot_nodes.append(slot)
		if data.slot_datas[i]:
			slot.set_slot_data(data.slot_datas[i])
	hotbar_edited.emit()
	update_selection_highlight(hotbar_data.selected_index)

func update_selection_highlight(index: int) -> void:
	for i in slot_nodes.size():
		# Add/remove a highlight style — simplest approach:
		slot_nodes[i].modulate = Color(1.5, 1.5, 1.5) if i == index else Color(1, 1, 1)
