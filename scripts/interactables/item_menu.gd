extends PanelContainer


const Slot = preload("uid://cscglddjwgx7y")

@onready var grid: GridContainer = $MarginContainer/GridContainer
var player: InventoryData
@export var recipes: Array[ItemData] = []

func populate_grid() -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in recipes.size():
		var slot = Slot.instantiate()
		grid.add_child(slot)

		var item = recipes[i]
		if item:
			var slot_data = SlotData.new()
			slot_data.item_data = item
			slot_data.quantity  = 1
			slot.set_slot_data(slot_data)

		var index := i
		slot.slot_clicked.connect(func(idx: int, _button: int) -> void:
			_on_recipe_slot_clicked(index)
		)

func set_recipe(player_recipe: Array[ItemData], inventory: InventoryData):
	recipes = player_recipe
	populate_grid()
	player = inventory

func _on_recipe_slot_clicked(index: int) -> void:
	var item = recipes[index]
	var matches: Dictionary = {}
	if not item.ingredients.keys():
		push_error("ItemMenu > Selected: No ingredients when crafting requested")
	if item:
		var i = 0
		for slot in player.slot_datas:
			if slot:
				print("ItemMenu > Selected: Looking through inventory.\nName: %s\nQuantity: %d" % [slot.item_data.name, slot.quantity])
				if slot.item_data in item.ingredients.keys():
					print("ItemMenu > Selected: Match!")
					if slot.quantity >= item.ingredients[slot.item_data]:
						print("ItemMenu > Selected: Quantity satisfied.")
						matches[slot.item_data] = 1
		debug_item_array(item.ingredients.keys())
		debug_item_array(matches.keys())
		for ingredient in item.ingredients.keys():
			if ingredient not in matches.keys():
				print("ItemMenu > Selected: Player cannot craft item")
				return
		print("ItemMenu > Selected: Player can craft item.")
		for old_slot in player.slot_datas:
			if not old_slot:
				var new_slot: SlotData
				new_slot.item_data = item #_on_recipe_slot_clicked: Invalid assignment of property or key 'item_data' with value of type 'Resource (ItemData)' on a base object of type 'Nil'.
				new_slot.quantity += 1
				old_slot = new_slot
				old_slot.quantity += 1
				for slot in player.slot_datas:
					if slot:
						if slot.item_data in item.ingredients.keys():
							if slot.quantity >= item.ingredients[slot.item_data]:
								slot.quantity -= item.ingredients[slot.item_data]
								if slot.quantity < 1:
									slot = null
									player.update(player)

func debug_item_array(arr: Array):
	print("ARRAY CONTENTS")
	for item in arr:
		print(item.name)
