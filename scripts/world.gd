extends Node3D

@onready var player: CharacterBody3D = $Player
var inventory_interface: Control

func _ready():
	inventory_interface = player.inventory_interface
	inventory_interface.set_player_inventory_data(player.inventory_data)
		
