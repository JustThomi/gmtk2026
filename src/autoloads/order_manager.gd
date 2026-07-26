extends Node

@export var order_time := 30
@export var base_payment := 5.5
@export var package_destroyed_value := -5.5
@export var failed_order_deduction := -5.5

@export var combo_step := 0.5
@export var combo_max := 10.0
@export var combo_window := 5.0
@export var crash_trick_loss := 2
@export var pedestrian_trick_loss := 1

var combo_count := 0
var combo_multiplier := 1.0
var combo_timer := 0.0
var time_remaining := 0.0
var timer_running := false
var distance: float
var order_count: int = 0
var money := 2.0
var package_health : float = 100.0
var is_order_picked : bool = false

var restaurant: Node3D
var destination: Node3D
var current_target: Node3D

var all_destinations = []
var all_restaurants  = []

signal order_completed
signal order_picked
signal order_started
signal combo_changed(multiplier: float, count: int)
signal combo_penalty(message: String, color: Color)

var timer_label: Label = null
var money_label: Label = null

var package_dict = {}

@onready var player: CharacterBody3D

func _ready():
	randomize()

func load_targets(restaurants, destinations):
	all_restaurants = restaurants
	all_destinations = destinations
	reset_combo()

func generate_order() -> void:
	clear_current_order()

	if all_restaurants.is_empty() or all_destinations.is_empty():
		return

	restaurant = all_restaurants.pick_random()
	destination = all_destinations.pick_random()

	restaurant.enable(player)
	current_target = restaurant
	package_health = 100.0

	start_timer()
	order_started.emit()
	player.arrow.show()
	
func set_timer_label(label: Label) -> void:
	timer_label = label
	update_timer_label()
	
func set_money_label(label: Label) -> void:
	money_label = label

func start_timer() -> void:
	time_remaining = order_time
	timer_running = true
	update_timer_label()

func order_picked_up():
	current_target = destination
	
	restaurant.disable()
	destination.enable(player)
	
	is_order_picked = true;
	order_picked.emit()

func order_finished():
	order_count += 1
	
	timer_running = false
	destination.disable()
	
	player.arrow.hide()
	is_order_picked = false
	timer_running = true
	
	var payment : float
	if package_health <= 0:
		payment = package_destroyed_value
	else:
		payment = base_payment * WeatherManager.get_payment_multiplier() * combo_multiplier * (package_health / 100.0)
	money += payment
	update_money_label()
	if combo_count > 0:
		combo_timer = combo_window
	
	order_completed.emit()
	await get_tree().create_timer(1.0).timeout
	generate_order()

func add_tricks(n: int) -> void:
	if n <= 0:
		return
	combo_count += n
	_recalc_multiplier()
	combo_timer = combo_window
	combo_changed.emit(combo_multiplier, combo_count)

func register_crash(is_big: bool) -> void:
	if combo_count <= 0:
		return
	if is_big:
		combo_penalty.emit("WIPEOUT!", Color("ff4d6d"))
		reset_combo()
		return
	combo_count = maxi(0, combo_count - crash_trick_loss)
	combo_timer = minf(combo_timer, combo_window * 0.5)
	_recalc_multiplier()
	combo_penalty.emit("CRASH! -%.1fx" % (crash_trick_loss * combo_step), Color("ff7a4d"))
	combo_changed.emit(combo_multiplier, combo_count)

func register_pedestrian_hit() -> void:
	if combo_count > 0:
		combo_count = maxi(0, combo_count - pedestrian_trick_loss)
		_recalc_multiplier()
		combo_changed.emit(combo_multiplier, combo_count)
	combo_penalty.emit("OUCH!", Color("ffa64d"))

func register_police_bust() -> void:
	if combo_count > 0:
		combo_penalty.emit("BUSTED!", Color("ff4d6d"))
	reset_combo()

func reset_combo() -> void:
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	combo_changed.emit(combo_multiplier, combo_count)

func _recalc_multiplier() -> void:
	combo_multiplier = clampf(1.0 + combo_count * combo_step, 1.0, combo_max)

func _process(delta: float) -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return
		
	if current_scene.name == "Map1":
	
		if current_target != null:
			distance = player.global_position.distance_to(current_target.global_position)
		
		if combo_count > 0:
			combo_timer -= delta
			if combo_timer <= 0.0:
				reset_combo()
		
		if timer_running:
			time_remaining -= delta

			if time_remaining <= 0.0:
				time_remaining = 0.0
				timer_running = false
				update_timer_label()
				money += failed_order_deduction
				update_money_label()
				generate_order()
				return
		
			update_timer_label()
		
		if money <= 0:
			lose_game()

func apply_fine(amount: float) -> void:
	money -= amount
	
	if money < 0:
		money = 0.0
	
	update_money_label()

func update_timer_label() -> void:
	if  timer_label == null:
		return
		
	var total_seconds := ceili(time_remaining)
	var minutes := total_seconds / 60.0
	var seconds := total_seconds % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]

func update_money_label() -> void:
	if money_label == null:
		return
		
	money_label.text = "%.2f" % [money]
	
func damage_package() -> void:
	package_health -= 10
	print("Current package health: " + str(package_health))

func clear_current_order() -> void:
	if is_instance_valid(restaurant):
		restaurant.disable()

	if is_instance_valid(destination):
		destination.disable()

	restaurant = null
	destination = null
	current_target = null

func lose_game() -> void:
	timer_label = null
	money_label = null
	get_tree().change_scene_to_file("res://src/ui/end_scene.tscn")

func reset_money() -> void:
	money = 100
