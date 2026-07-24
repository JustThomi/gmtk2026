extends Node

signal weather_changed(is_bad: bool)

enum Weather { CLEAR, RAIN, STORM, FOG }

var multipliers = { Weather.CLEAR: 1.0, Weather.RAIN: 1.25, Weather.STORM: 2.0, Weather.FOG: 1.5 }

var current_weather: Weather = Weather.CLEAR

@export var min_change_time := 20
@export var max_change_time := 60

func _ready():
	randomize()
	weather_loop()

func weather_loop() -> void:
		while true:
			var wait_time := randf_range(min_change_time, max_change_time)

			await get_tree().create_timer(wait_time).timeout
			change_random_weather()


func change_random_weather():
	var possible_weathers = [Weather.CLEAR, Weather.CLEAR, Weather.CLEAR, Weather.RAIN, Weather.FOG, Weather.STORM]
	
	current_weather = possible_weathers.pick_random()
	weather_changed.emit(current_weather)

func get_payment_multiplier() -> float:
	return multipliers[current_weather]
