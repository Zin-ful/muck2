extends Resource
class_name ItemData
@export var name:String = ""
@export_multiline var description:String = ""
@export var stackable:bool = false
@export var consumable:bool = true
@export var texture:Texture
@export var mesh: Mesh
@export var scene: PackedScene

func use() -> Array:
	var return_value: Array = scene.use()
	return return_value

func get_scene() -> PackedScene:
	return scene
