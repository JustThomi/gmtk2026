extends Node

@export var order_time := 30

var time_remaining := 0.0
var timer_running := false
var distance: float

var restaurant: Node3D
var destination: Node3D
var current_target: Node3D

var all_destinations = []
var all_restaurants  = []

signal order_completed
signal order_picked
signal order_started

var timer_label: Label = null

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
	
	start_timer()
	
func set_timer_label(label: Label) -> void:
	timer_label = label
	update_timer_label()

func start_timer() -> void:
	time_remaining = order_time
	timer_running = true
	update_timer_label()

func order_picked_up():
	current_target = destination
	
	restaurant.disable()
	destination.enable(player)
	
	order_picked.emit()

func order_finished():
	timer_running = false
	destination.disable()
	
	time_remaining += 10

	timer_running = true
	generate_order()
	# TODO: Reward player here
	
	order_completed.emit()
	await get_tree().create_timer(1.0).timeout
	generate_order()

func _process(delta: float) -> void:
	if current_target != null:
		distance = player.global_position.distance_to(current_target.global_position)
	
	if timer_running:
		time_remaining -= delta

		if time_remaining <= 0.0:
			time_remaining = 0.0
			timer_running = false
			update_timer_label()
			get_tree().reload_current_scene()
			return

		update_timer_label()

func update_timer_label() -> void:
	var total_seconds := ceili(time_remaining)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]
