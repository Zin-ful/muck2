extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)

signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

@export var slot_datas: Array[SlotData]

func grab_slot(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func drop_slot(grabbed_slot: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	var return_slot_data: SlotData
	if slot_data and slot_data.check_merge(grabbed_slot):
		slot_data.merge(grabbed_slot)
	else:
		slot_datas[index] = grabbed_slot
		return_slot_data = slot_data
	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot(grabbed_slot: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		slot_datas[index] = grabbed_slot.single_slot()
	elif slot_data.check_merge_from_drop(grabbed_slot):
		slot_data.drop_merge(grabbed_slot)
		
	inventory_updated.emit(self)
	
	if grabbed_slot.quantity > 0:
		return grabbed_slot
	else:
		return null

func on_slot_clicked(index: int, button: int):
	inventory_interact.emit(self, index, button)

func pick_up_slot_data(slot_data:SlotData) -> bool:
	
	for index in slot_datas.size():
		if slot_datas[index]:
			if slot_datas[index].check_merge(slot_data):
				slot_datas[index].merge(slot_data)
				inventory_updated.emit(self)
				return true
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			return true
	return false
