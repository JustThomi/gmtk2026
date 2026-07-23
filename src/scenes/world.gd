extends Node3D

func _ready() -> void:
	var r = $Restaurants.get_children()
	var h = $Homes.get_children()
	
	OrderManager.player = $CharacterBody3D
	OrderManager.load_targets(r, h)
	OrderManager.generate_order()
