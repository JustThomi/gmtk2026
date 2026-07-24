extends MarginContainer

@onready var weather_icon: TextureRect = $MarginContainer/HBoxContainer/TextureRect

var all_icons := [
	load("res://assets/ui/weather/clear.png"),
	load("res://assets/ui/weather/rain.png"),
	load("res://assets/ui/weather/storm.png"),
	load("res://assets/ui/weather/fog.png"),
]

func _ready():
	WeatherManager.weather_changed.connect(_on_weather_changed)
	weather_icon.texture = all_icons[WeatherManager.current_weather]

func _on_weather_changed(_is_bad):
	weather_icon.texture = all_icons[WeatherManager.current_weather]
