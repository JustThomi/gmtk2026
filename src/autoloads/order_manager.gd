extends Node

var distance: float

var restaurant: Node3D
var destination: Node3D
var current_target: Node3D

var all_destinations = []
var all_restaurants  = []

signal order_completed
signal order_picked
signal order_started

@onready var player: CharacterBody3D

func load_targets(restaurants, destinations):
	all_restaurants = restaurants
	all_destinations = destinations

func generate_order():
	randomize()
	restaurant = all_restaurants[randi_range(0, len(all_restaurants) - 1)]
	destination = all_destinations[randi_range(0, len(all_destinations) - 1)]
	
	restaurant.enable(player)
	
	current_target = restaurant
	
	order_started.emit()
	player.arrow.show()

func order_picked_up():
	current_target = destination
	
	restaurant.disable()
	destination.enable(player)
	
	order_picked.emit()

func order_finished():
	destination.disable()
	generate_order()
	# TODO: Reward player here
	
	order_completed.emit()
	await get_tree().create_timer(1.0).timeout
	generate_order()

func _process(_delta: float) -> void:
	if current_target != null:
		distance = player.global_position.distance_to(current_target.global_position)
