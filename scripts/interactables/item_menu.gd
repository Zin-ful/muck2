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

		var empty_index := -1
		for i in player.slot_datas.size():
			if not player.slot_datas[i]:
				empty_index = i
				break

		if empty_index == -1:
			print("ItemMenu > Selected: No empty slot available")
			return

		var new_slot := SlotData.new()
		new_slot.item_data = item
		new_slot.quantity = 1
		player.slot_datas[empty_index] = new_slot

		for i in player.slot_datas.size():
			var slot = player.slot_datas[i]
			if slot and slot.item_data in item.ingredients.keys():
				if slot.quantity >= item.ingredients[slot.item_data]:
					slot.quantity -= item.ingredients[slot.item_data]
					if slot.quantity < 1:
						player.slot_datas[i] = null

		player.update(player)

func debug_item_array(arr: Array):
	print("ARRAY CONTENTS")
	for item in arr:
		print(item.name)
