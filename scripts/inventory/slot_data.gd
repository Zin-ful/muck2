extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 99

@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func check_merge(other_slot: SlotData) -> bool:
	return item_data == other_slot.item_data and item_data.stackable and quantity + other_slot.quantity < MAX_STACK_SIZE

func check_merge_from_drop(other_slot: SlotData) -> bool:
	return item_data == other_slot.item_data and item_data.stackable and quantity < MAX_STACK_SIZE


func single_slot() -> SlotData:
	if quantity < 1:
		return
	var new_slot = duplicate()
	new_slot.quantity = 1
	quantity -= new_slot.quantity
	return new_slot
	
	
func merge(other_slot: SlotData):
	quantity += other_slot.quantity

func drop_merge(other_slot: SlotData):
	if not other_slot.quantity:
		return
	quantity += 1
	other_slot.quantity -= 1

func get_scene() -> PackedScene:
	return item_data.get_scene()

func use() -> Array:
	return item_data.use()

func set_quantity(value: int) -> void:
	quantity = value
	if quantity > 1 and not item_data.stackable:
		quantity = 1
		push_error("%s is not stackable, setting to 1", item_data.name)
