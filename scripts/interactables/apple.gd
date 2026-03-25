extends StaticBody3D

@export var type: String
@export var value: int


func use():
	return [type, value]
