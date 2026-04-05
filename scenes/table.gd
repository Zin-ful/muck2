extends StaticBody3D

@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

func open_ui(): 
	sub_viewport_container.visible = !sub_viewport_container.visible
