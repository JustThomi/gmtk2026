extends Node

var distance: int

var restaurant: Node3D
var destination: Node3D
var current_target: Node3D

var all_destinations = []
var all_restaurants  = []

@onready var player: CharacterBody3D

func generate_order():
	restaurant = all_restaurants[randi_range(0, len(all_restaurants))]
	destination = all_destinations[randi_range(0, len(all_destinations))]
	
	current_target = restaurant

func order_picked_up():
	current_target = destination

func order_finished():
	# TODO: Reward player here
	pass

func _process(_delta: float) -> void:
	distance = player.global_position.distance_to(current_target.global_position)
