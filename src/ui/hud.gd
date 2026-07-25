extends Control

@onready var phone: MarginContainer = $Phone
@onready var order_map: Window = $OrdersMap

# TODO: remove this if we implement the map solution
@onready var orders_page: MarginContainer = $Phone/OrdersPage

@onready var active_order_page: MarginContainer = $Phone/ActiveOrderPage
@onready var active_order_image: TextureRect = $Phone/ActiveOrderPage/MenuContainer/TextureRect
@onready var order_completed_page: MarginContainer = $Phone/OrderComplete

@onready var distance_value: Label = $Phone/ActiveOrderPage/MenuContainer/TopBar/HBoxContainer/DistanceValue
@onready var order_count: Label = $Phone/ActiveOrderPage/MenuContainer/HBoxContainer/CompletedCount

@onready var weather_label: Label = $Phone/ActiveOrderPage/MenuContainer/TopBar/Weather/HBoxContainer/WeatherName
@onready var weather_icon: TextureRect = $Phone/ActiveOrderPage/MenuContainer/TopBar/Weather/HBoxContainer/TextureRect

@export var phone_offset:float = 200.0

var restaurant_image: Texture = preload("res://assets/ui/mickeychickey.png")
var house_image: Texture = preload("res://assets/ui/house.png")

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
	
	if Input.is_action_just_pressed("tab"):
		phone.position.y -= phone_offset
	
	if Input.is_action_just_released("tab"):
		phone.position.y += phone_offset

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
