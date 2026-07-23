extends Node

var distance: float

var restaurant: Node3D
var destination: Node3D
var current_target: Node3D

var all_destinations = []
var all_restaurants  = []

@onready var player: CharacterBody3D

func load_targets(restaurants, destinations):
	all_restaurants = restaurants
	all_destinations = destinations

func generate_order():
	randomize()
	restaurant = all_restaurants[randi_range(0, len(all_restaurants) - 1)]
	destination = all_destinations[randi_range(0, len(all_destinations) - 1)]
	
	restaurant.enable()
	
	current_target = restaurant

func order_picked_up():
	current_target = destination
	
	restaurant.disable()
	destination.enable()

func order_finished():
	destination.disable()
	player.arrow.hide()
	# TODO: Reward player here

func _process(_delta: float) -> void:
	if current_target != null:
		distance = player.global_position.distance_to(current_target.global_position)
