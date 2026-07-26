extends Node

@export var order_time := 30
@export var base_payment := 5.5
@export var package_destroyed_value := -5.5
@export var failed_order_deduction := -5.5
@export var points_on_order_complete := 100
@export var points_deducted_on_crash := -30

@export var combo_step := 0.5
@export var combo_max := 10.0
@export var combo_window := 5.0
@export var crash_trick_loss := 2
@export var pedestrian_trick_loss := 1
@export var money_sounds : Array[AudioStream] = []
@export var crash_sounds : Array[AudioStream] = []
@export var wipeout_sounds : Array[AudioStream] = []
@export var busted_sounds : Array[AudioStream] = []

var sfx_audio_player : AudioStreamPlayer
var money_audio_player : AudioStreamPlayer
var combo_count := 0
var combo_multiplier := 1.0
var combo_timer := 0.0
var time_remaining := 0.0
var timer_running := false
var distance: float
var order_count: int = 0
var money := 150.0
var package_health : float = 100.0
var is_order_picked : bool = false
var points := 0;

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
	money_audio_player = AudioStreamPlayer.new()
	add_child(money_audio_player)
	
	sfx_audio_player = AudioStreamPlayer.new()
	add_child(sfx_audio_player)

func load_targets(restaurants, destinations):
	all_restaurants = restaurants
	all_destinations = destinations
	reset_combo()

func generate_order() -> void:
	clear_current_order()

	if all_restaurants.is_empty() or all_destinations.is_empty():
		return

	var restaurant_building: Node3D = all_restaurants.pick_random()
	var destination_building: Node3D = all_destinations.pick_random()

	restaurant = restaurant_building.get_node_or_null("Target")
	destination = destination_building.get_node_or_null("Target")

	if restaurant == null:
		push_error("Restaurant has no Target child: " + restaurant_building.name)
		return

	if destination == null:
		push_error("Destination has no Target child: " + destination_building.name)
		return

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
	update_money_label()

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
	var points_to_get : int
	if package_health <= 0:
		payment = package_destroyed_value
		points_to_get = package_destroyed_value
	else:
		payment = base_payment * WeatherManager.get_payment_multiplier() * combo_multiplier * (package_health / 100.0)
		points_to_get = points_on_order_complete + WeatherManager.get_payment_multiplier() * combo_multiplier * (package_health / 100)
	
	if payment > 0:
		play_money_sound()
	
	money += payment
	points += points_to_get
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
		play_sfx(wipeout_sounds, 0.85, 1.05)
		reset_combo()
		return
	combo_count = maxi(0, combo_count - crash_trick_loss)
	combo_timer = minf(combo_timer, combo_window * 0.5)
	_recalc_multiplier()
	combo_penalty.emit("CRASH! -%.1fx" % (crash_trick_loss * combo_step), Color("ff7a4d"))
	combo_changed.emit(combo_multiplier, combo_count)
	play_sfx(crash_sounds, 0.9, 1.1)
	points += points_deducted_on_crash

func register_pedestrian_hit() -> void:
	if combo_count > 0:
		combo_count = maxi(0, combo_count - pedestrian_trick_loss)
		_recalc_multiplier()
		combo_changed.emit(combo_multiplier, combo_count)
	combo_penalty.emit("OUCH!", Color("ffa64d"))

func register_police_bust() -> void:
	play_sfx(busted_sounds, 0.95, 1.05)
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

func apply_point_deduction(ammount: int) -> void:
	points -= ammount
	
	if points < 0:
		points = 0

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

func play_sfx(sound_list: Array[AudioStream], pitch_min := 0.9, pitch_max := 1.1):
	if sound_list.size() > 0 and sfx_audio_player:
		sfx_audio_player.stream = sound_list.pick_random()
		sfx_audio_player.pitch_scale =randf_range(pitch_min, pitch_max)
		sfx_audio_player.play()

func play_money_sound():
	if money_sounds.size() > 0 and money_audio_player:
		money_audio_player.stream = money_sounds[randi() % money_sounds.size()]
		money_audio_player.pitch_scale = randf_range(0.95, 1.05)
		money_audio_player.play()

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
	LeaderboardManager.add_current_score()
	get_tree().change_scene_to_file("res://src/ui/end_scene.tscn")

func reset_game() -> void:
	money = 100
	points = 0
