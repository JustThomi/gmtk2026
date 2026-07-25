extends Node

signal weather_changed(is_bad: bool)

enum Weather { CLEAR, RAIN, STORM, FOG }

var multipliers = { Weather.CLEAR: 1.0, Weather.RAIN: 1.25, Weather.STORM: 2.0, Weather.FOG: 1.5 }

var current_weather: Weather = Weather.CLEAR
var lightning_running := false

signal lightning

@export var min_change_time := 3
@export var max_change_time := 3

func _ready():
	randomize()
	weather_loop()

func weather_loop() -> void:
		while true:
			var wait_time := randf_range(min_change_time, max_change_time)

			await get_tree().create_timer(wait_time).timeout
			change_random_weather()


func change_random_weather():
	var possible_weathers = [Weather.STORM]
	
	current_weather = possible_weathers.pick_random()
	if current_weather == Weather.STORM and !lightning_running:
		lightning_loop()
		
	weather_changed.emit(current_weather)

func get_payment_multiplier() -> float:
	return multipliers[current_weather]

func lightning_loop() -> void:
	lightning_running = true

	while current_weather == Weather.STORM:
		await get_tree().create_timer(randf_range(2.0, 8.0)).timeout

		if current_weather != Weather.STORM:
			break

		lightning.emit()

	lightning_running = false
