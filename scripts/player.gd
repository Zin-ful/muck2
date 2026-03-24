extends CharacterBody3D

@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var interact_ray: RayCast3D = $Head/Camera/InteractRay

@export var inventory_data: InventoryData

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
	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	if Input.is_action_just_pressed("menu"):
		toggle_inventory_interface()
	if Input.is_action_just_pressed("interact"):
		interact()

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

func toggle_inventory_interface(owner=null):
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		inventory_interface.visible = false
	else: 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		inventory_interface.visible = true
	if owner:
		inventory_interface.set_external_inventory(owner)

func interact():
	if interact_ray.is_colliding():
		var object = interact_ray.get_collider()
		if object.has_method("player_open_storage"):
			var data = object.player_open_storage()
			if data:
				toggle_inventory_interface(object)
