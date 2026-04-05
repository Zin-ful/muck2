extends Resource
class_name ItemData
@export var name:String = ""
@export_multiline var description:String = ""
@export var texture:Texture
@export var mesh: Mesh
@export var scene: PackedScene
@export_group("Modifiers")
@export var stackable:bool = false
@export var consumable:bool = true
@export_group("Crafting")
@export var craftable:bool = false
@export var ingredients: Dictionary[ItemData, int]

func _ready() -> void:
	if craftable and not ingredients:
		push_error("You need to assign ingredients to ", name)
	if ingredients and not craftable:
		push_error("Ingredients assigned but %s is not marked as craftable." % name)
func use() -> Array:
	var return_value: Array = scene.use()
	return return_value

func get_scene() -> PackedScene:
	return scene
