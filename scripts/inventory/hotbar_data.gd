extends InventoryData
class_name HotBarData

signal hotbar_selection_changed(index: int)

var selected_index: int = 0: set = set_selected_index

func set_selected_index(value: int) -> void:
	selected_index = clampi(value, 0, slot_datas.size() - 1)
	hotbar_selection_changed.emit(selected_index)

func get_selected_slot() -> SlotData:
	return slot_datas[selected_index]
