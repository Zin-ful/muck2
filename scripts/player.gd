extends CharacterBody3D


signal inventory_updated(inventory_data: InventoryData)

#inventory UI
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var interact_ray: RayCast3D = $Head/Camera/InteractRay
@onready var external_inventory: PanelContainer = $UI/InventoryInterface/ExternalInventory
@export var inventory_data: InventoryData

#UI
@onready var item_holder: Marker3D = $Head/Camera/ItemHolder
@export var hotbar_data: HotBarData
@onready var hot_bar: PanelContainer = $UI/HotBarInterface/HotBar

@onready var health: TextureProgressBar = $UI/Stats/Health
@onready var hunger: TextureProgressBar = $UI/Stats/Hunger
@onready var stamina: TextureProgressBar = $UI/Stats/Stamina


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


func _ready():
	$".".scale = Vector3(SCALE,SCALE,SCALE)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for child in %BodyCollision.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
	health.value = 100
	hunger.value = 100
	stamina.value = 100
	hot_bar.set_hotbar_data(hotbar_data)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	if Input.is_action_just_pressed("menu"):
		toggle_inventory_interface()
	if Input.is_action_just_pressed("interact"):
		interact()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			hotbar_data.selected_index += 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			hotbar_data.selected_index -= 1
		var item: SlotData = hotbar_data.get_selected_slot()
		if item_holder.get_child(0) and not item:
			remove_item(item_holder.get_child(0))
		if item:
			display_item(item)
		
			
	if Input.is_action_just_pressed("use"):
		use()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

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
		inventory_interface.visible = false
		if external_inventory.visible:
			external_inventory.visible = false
			
	else: 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		inventory_interface.visible = true
		
func interact():
	if interact_ray.is_colliding():
		var object = interact_ray.get_collider()
		if object.has_method("player_open_storage"):
			var data = object.player_open_storage()
			if data:
				print("Chest has an assigned inventory")
				toggle_inventory_interface(object)

func get_current_transform() -> Transform3D:
	var drop_position = head.global_position + (-head.global_transform.basis.z * 1.5)  # 1.5 units in front
	return Transform3D(head.global_transform.basis, drop_position)

func use():
	var item = item_holder.get_child(0)
	if not item:
		return
	var result: Array = item.use()
	print(result[0])
	print(result[1])
	var slot_item: SlotData = hotbar_data.get_selected_slot()
	#failed to update hotbar
	slot_item.quantity -= 1
	if slot_item.quantity < 1:
		slot_item = null
		remove_child(item)
		item.queue_free()

func display_item(item: SlotData):
	for child in item_holder.get_children():
		child.queue_free()
	if item:
		var instance = item.get_scene().instantiate()
		item_holder.add_child(instance)

func remove_item(child):
	remove_child(child)
	child.queue_free()
