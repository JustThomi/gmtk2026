extends Node3D

@onready var timer_label: Label = $HUD/TimerLabel
@onready var money_label: Label = $HUD/MoneyLabel

func _ready() -> void:
	var r = $Restaurants.get_children()
	var h = $Homes.get_children()
	
	OrderManager.player = $CharacterBody3D
	OrderManager.set_timer_label(timer_label)
	OrderManager.set_money_label(money_label)
	OrderManager.start_timer()
	OrderManager.load_targets(r, h)
	OrderManager.generate_order()
	WeatherManager.weather_changed.connect(_on_weather_changed)
	
func _on_weather_changed(weather: WeatherManager.Weather):
	return 1
