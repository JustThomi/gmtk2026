extends Node3D

@onready var timer_label: Label = $HUD/TimerLabel

func _ready() -> void:
	var r = $Restaurants.get_children()
	var h = $Homes.get_children()
	
	OrderManager.player = $CharacterBody3D
	OrderManager.set_timer_label(timer_label)
	OrderManager.start_timer()
	OrderManager.load_targets(r, h)
	OrderManager.generate_order()
