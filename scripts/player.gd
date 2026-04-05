extends CharacterBody3D


signal inventory_updated(inventory_data: InventoryData)

#inventory UI
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var interact_ray: RayCast3D = $Head/Camera/InteractRay
@onready var external_inventory: PanelContainer = $UI/InventoryInterface/ExternalInventory
@export var inventory_data: InventoryData
@onready var player_inventory: PanelContainer = $UI/InventoryInterface/PlayerInventory


#UI
@onready var item_holder: Marker3D = $Head/Camera/ItemHolder
@export var hotbar_data: HotBarData
@onready var hot_bar: PanelContainer = $UI/HotBarInterface/HotBar
@onready var hot_bar_interface: Control = $UI/HotBarInterface
@export var recipes: Array[ItemData] = []

@onready var health: TextureProgressBar = $UI/Stats/Health
@onready var hunger: TextureProgressBar = $UI/Stats/Hunger
@onready var stamina: TextureProgressBar = $UI/Stats/Stamina

@export var stamina_drain = 2
@export var max_stamina = 1000
@export var hunger_drain = 1
@export var max_hunger = 5000
@export var health_regen = 1
@export var max_health = 1000
var speed
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 8.0
@export var JUMP_VELOCITY = 4.8
@export var SCALE = 1.0

const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.02
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.1

var gravity = 15

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var interact_label: Label = $UI/InteractLabel

var hotbar_root_position = null

func _process(delta: float) -> void:
	if interact_ray.is_colliding():
		interact_label.visible = true
	else:
		interact_label.visible = false

func _ready():
	$".".scale = Vector3(SCALE,SCALE,SCALE)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for child in %BodyCollision.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
	health.max_value = max_health
	hunger.max_value = max_hunger
	stamina.max_value = max_stamina
	health.value = max_health
	hunger.value = max_hunger
	stamina.value = max_stamina
	if stamina_drain < 2:
		push_error("stamina_drain needs to be an int higher than 1")
	if hunger_drain < 1:
		push_error("hunger_drain needs to be an int higher than 0")
	hot_bar.set_hotbar_data(hotbar_data)
	hotbar_root_position = hot_bar_interface.position

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(60))
	if Input.is_action_just_pressed("menu"):
		toggle_inventory_interface()
	if Input.is_action_just_pressed("interact"):
		interact()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			hotbar_data.selected_index += 1
			display_item(hotbar_data.get_selected_slot())
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			hotbar_data.selected_index -= 1
			display_item(hotbar_data.get_selected_slot())

	if Input.is_action_just_pressed("use"):
		if not hotbar_data.get_selected_slot():
			return
		use()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint"):
		if stamina.value > 1:
			stamina.value -= stamina_drain
			if stamina.value < 0:
				stamina.value = 0
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
	else:
		speed = WALK_SPEED
		if stamina.value < max_stamina and hunger.value:
			stamina.value += stamina_drain / 2
			hunger.value -= hunger_drain
			if stamina.value > max_stamina:
				stamina.value = max_stamina
	if health.value < max_health:
		hunger.value -= hunger_drain
		health.value += health_regen
		

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func toggle_inventory_interface(external_owner = null):
	if external_owner:
		inventory_interface.set_external_inventory(external_owner)
		external_inventory.visible = (not external_inventory.visible)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().warp_mouse(Vector2(0,0))
		inventory_interface.visible = false
		if external_inventory.visible:
			external_inventory.visible = false
		hot_bar_interface.position = hotbar_root_position
			
	else: 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		inventory_interface.visible = true
		var offset = player_inventory.size
		offset.x = 10
		offset.y += 25
		hot_bar_interface.position = player_inventory.position + offset
		
func interact():
	if interact_ray.is_colliding():
		print("Player > Interacting: Is colliding")
		var object = interact_ray.get_collider()
		if object.has_method("player_open_storage"):
			print("Player > Interacting >  Ray: Found Storage Object")
			var data = object.player_open_storage()
			if data:
				toggle_inventory_interface(object)
		elif object.has_method("pickup"):
			print("Player > Interacting > Ray: Found Pickup Object")
			object.pickup(inventory_data)
			inventory_updated.emit(inventory_data)
		elif object.has_method("open_ui"):
			
			print("Player > Interacting > Ray: Found Interactable UI")
			var UI_scene = object.open_ui().instantiate()
			if UI_scene not in inventory_interface.get_children():
				inventory_interface.add_child(UI_scene)
				UI_scene.position = external_inventory.position
				UI_scene.size = external_inventory.size
				UI_scene.set_recipe(recipes, inventory_data)
			else:
				remove_child(UI_scene)
				UI_scene.queue_free()
			toggle_inventory_interface()
		return
	print("Player > Interacting: Is NOT colliding")

func get_current_transform() -> Transform3D:
	var drop_position = head.global_position + (-head.global_transform.basis.z * 1.5)  # 1.5 units in front
	return Transform3D(head.global_transform.basis, drop_position)

func use():
	var item = item_holder.get_child(0)
	if not item:
		return
	var result: Array = item.use()
	if result[0] == "empty":
		return
	print("Player > Use: Using type = ", result[0])
	print("Player > Use: Using value = ", result[1])
	var index = hotbar_data.selected_index
	var slot_item: SlotData = hotbar_data.slot_datas[index]
	if result[0] != "tool":
		if result[0] == "restore_all":
			health.value += result[1] / 2
			hunger.value += result[1] / 3
			stamina.value += result[1] / 4
			if health.value > max_health:
				health.value = max_health
			if hunger.value > max_hunger:
				hunger.value = max_hunger
			if stamina.value > max_stamina:
				stamina.value = max_stamina
		elif result[0] == "restore_hunger":
			hunger.value += result[1]
			if hunger.value > max_hunger:
				hunger.value = max_hunger
		elif result[0] == "restore_health":
			health.value += result[1]
			if health.value > max_health:
				health.value = max_health
		elif result[0] == "restore_stamina":
			stamina.value += result[1]
			if stamina.value > max_stamina:
				stamina.value = max_stamina
		slot_item.quantity -= 1
		if slot_item.quantity < 1:
			hotbar_data.slot_datas[index] = null
			remove_item(item_holder.get_child(0))
		hotbar_data.inventory_updated.emit(hotbar_data)

func display_item(item: SlotData):
	for child in item_holder.get_children():
		child.queue_free()
	if item:
		var instance = item.get_scene().instantiate()
		instance.set_hold_size()
		item_holder.add_child(instance)

func remove_item(child):
	remove_child(child)
	child.queue_free()

func _on_hot_bar_hotbar_edited() -> void: # to make sure an item leaves when moved, emmited from hotbar.gd
	display_item(hotbar_data.get_selected_slot())
