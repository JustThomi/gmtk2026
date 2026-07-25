extends Control

@onready var phone: MarginContainer = $Phone
@onready var order_map: Window = $OrdersMap
@onready var upgrade_window: Window = $UpgradeWindow

# TODO: remove this if we implement the map solution
@onready var orders_page: MarginContainer = $Phone/OrdersPage

@onready var active_order_page: MarginContainer = $Phone/ActiveOrderPage
@onready var active_order_image: TextureRect = $Phone/ActiveOrderPage/MenuContainer/TextureRect
@onready var order_completed_page: MarginContainer = $Phone/OrderComplete

@onready var distance_value: Label = $Phone/ActiveOrderPage/MenuContainer/TopBar/HBoxContainer/DistanceValue
@onready var order_count: Label = $Phone/ActiveOrderPage/MenuContainer/CompleteContainer/CompletedCount

@onready var weather_label: Label = $Phone/ActiveOrderPage/MenuContainer/TopBar/Weather/HBoxContainer/WeatherName
@onready var weather_icon: TextureRect = $Phone/ActiveOrderPage/MenuContainer/TopBar/Weather/HBoxContainer/TextureRect

@onready var multiplier_count_label: Label = $Phone/ActiveOrderPage/MenuContainer/BonusContainer/MultiplierCount
@onready var tier_label: Label = $Phone/ActiveOrderPage/MenuContainer/BonusContainer/TierLabel
@onready var combo_bar: ProgressBar = $Phone/ActiveOrderPage/MenuContainer/ComboBar
@onready var combo_fill_style: StyleBoxFlat = combo_bar.get_theme_stylebox("fill") as StyleBoxFlat
@onready var health_bar: ProgressBar = $Phone/ActiveOrderPage/MenuContainer/HealthBar
@onready var health_value: Label = $Phone/ActiveOrderPage/MenuContainer/HealthContainer/HealthValue
@onready var health_fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill") as StyleBoxFlat

@export var phone_offset:float = 300.0

var restaurant_image: Texture = preload("res://assets/ui/phone/mickeychickey.png")
var house_image: Texture = preload("res://assets/ui/phone/house.png")

var weather_icons := [
	load("res://assets/ui/weather/clear.png"),
	load("res://assets/ui/weather/rain.png"),
	load("res://assets/ui/weather/storm.png"),
	load("res://assets/ui/weather/fog.png"),
]

var weather_labels := ["Sunny", "Rain", "Storm", "Fog"]

func _ready() -> void:
	OrderManager.order_completed.connect(_on_order_completed)
	OrderManager.order_started.connect(_on_order_started)
	OrderManager.order_picked.connect(_on_order_picked)
	
	WeatherManager.weather_changed.connect(_on_weather_changed)
	weather_icon.texture = weather_icons[WeatherManager.current_weather]
	weather_label.text = weather_labels[WeatherManager.current_weather]
	
	orders_page.hide()
	active_order_page.show()
	
	order_map.hide()

func _process(_delta: float) -> void:
	if OrderManager.current_target != null:
		distance_value.text = str(int(OrderManager.distance))
	
	multiplier_count_label.text = "x%.1f" % OrderManager.combo_multiplier
	_update_combo_ui()
	_update_health_ui()
	
	if Input.is_action_just_pressed("tab"):
		phone.position.y -= phone_offset
	
	if Input.is_action_just_released("tab"):
		phone.position.y += phone_offset

func _update_combo_ui() -> void:
	if OrderManager.combo_window > 0.0:
		combo_bar.value = OrderManager.combo_timer / OrderManager.combo_window

	if OrderManager.combo_count <= 0:
		tier_label.text = ""
		return

	var m := OrderManager.combo_multiplier
	var tier_word := "NICE!"
	var tier_color := Color("9be7ff")
	if m >= 7.0:
		tier_word = "INSANE!"
		tier_color = Color("ff4d6d")
	elif m >= 5.0:
		tier_word = "SICK!"
		tier_color = Color("ff884d")
	elif m >= 3.5:
		tier_word = "GNARLY!"
		tier_color = Color("ffcf4d")
	elif m >= 2.0:
		tier_word = "RAD!"
		tier_color = Color("7dff9b")

	tier_label.text = tier_word
	tier_label.add_theme_color_override("font_color", tier_color)
	if combo_fill_style:
		combo_fill_style.bg_color = tier_color

func _update_health_ui() -> void:
	var hp := clampf(OrderManager.package_health, 0.0, 100.0)
	health_bar.value = hp
	health_value.text = "%d%%" % int(hp)
	if health_fill_style:
		health_fill_style.bg_color = Color("ff4d6d").lerp(Color("6dff8f"), hp / 100.0)

func _on_weather_changed(_is_bad):
	weather_icon.texture = weather_icons[WeatherManager.current_weather]
	weather_label.text = weather_labels[WeatherManager.current_weather]

func _on_order_started():
	active_order_page.show()
	order_completed_page.hide()
	active_order_image.texture = restaurant_image

func _on_order_picked():
	active_order_image.texture = house_image

func _on_order_completed():
	order_completed_page.show()
	active_order_page.hide()
	order_count.text = str(OrderManager.order_count)

func _on_order_button_pressed() -> void:
	# TODO: trigger orders here
	orders_page.hide()
	active_order_page.show()

func _on_orders_map_close_requested():
	order_map.hide()

func _on_upgrade_button_pressed():
	upgrade_window.show()
