extends Node3D

@onready var timer_label: Label = $HUD/TimerLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var environment: Environment = world_environment.environment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var rain: GPUParticles3D = $Rain

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
	WeatherManager.lightning.connect(_on_lightning)
	
func _on_weather_changed(weather):
	match weather:
		WeatherManager.Weather.CLEAR:
			environment.volumetric_fog_enabled = false
			sun.shadow_opacity = 1.0
			environment.background_color = Color(1.0, 0.95, 0.75, 1.0)
			environment.ambient_light_energy = 1.0
			fade_out_rain()

		WeatherManager.Weather.FOG:
			environment.volumetric_fog_enabled = true
			sun.shadow_opacity = 0.2
			environment.volumetric_fog_density = 0.02
			environment.background_color = Color(0.70, 0.72, 0.75)
			environment.ambient_light_energy = 0.7
			fade_out_rain()
		
		WeatherManager.Weather.RAIN:
			sun.shadow_opacity = 0.2
			sun.light_energy = 0.4
			environment.background_color = Color(0.35, 0.40, 0.50)
			environment.ambient_light_energy = 0.6
			fade_in_rain()
		
		WeatherManager.Weather.STORM:
			sun.shadow_opacity = 0.2
			sun.light_energy = 0.25
			environment.background_color = Color(0.136, 0.209, 0.304, 1.0)
			environment.ambient_light_energy = 0.7
			fade_in_rain()

func _on_lightning():
	sun.light_energy = 3.0
	await get_tree().create_timer(0.08).timeout
	sun.light_energy = 0.25

func fade_in_rain():
	rain.emitting = true
	var tween := create_tween()
	tween.tween_property(rain, "amount_ratio", 1.0, 2.0)

func fade_out_rain():
	var tween := create_tween()
	tween.tween_property(rain, "amount_ratio", 0.0, 2.0)
	await tween.finished
	rain.emitting = false
