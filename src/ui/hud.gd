extends Control

@onready var phone: MarginContainer = $Phone
@onready var order_map: Window = $OrdersMap

# TODO: remove this if we implement the map solution
@onready var orders_page: MarginContainer = $Phone/OrdersPage

@onready var active_order_page: MarginContainer = $Phone/ActiveOrderPage
@onready var active_order_image: TextureRect = $Phone/ActiveOrderPage/MenuContainer/TextureRect
@onready var order_completed_page: MarginContainer = $Phone/OrderComplete

@onready var distance_value: Label = $Phone/ActiveOrderPage/MenuContainer/DistanceValue

var restaurant_image: Texture = preload("res://assets/ui/mickeychickey.png")
var house_image: Texture = preload("res://assets/ui/house.png")


func _ready() -> void:
	OrderManager.order_completed.connect(_on_order_completed)
	OrderManager.order_started.connect(_on_order_started)
	OrderManager.order_picked.connect(_on_order_picked)

	
	orders_page.hide()
	active_order_page.show()
	
	order_map.hide()

func _process(_delta: float) -> void:
	if OrderManager.current_target != null:
		distance_value.text = str(int(OrderManager.distance))

func _on_order_started():
	active_order_page.show()
	order_completed_page.hide()
	active_order_image.texture = restaurant_image

func _on_order_picked():
	active_order_image.texture = house_image

func _on_order_completed():
	order_completed_page.show()
	active_order_page.hide()

func _on_mouse_detector_mouse_entered() -> void:
	phone.position.y -= 108.0

func _on_mouse_detector_mouse_exited() -> void:
	phone.position.y += 108.0

func _on_order_button_pressed() -> void:
	# TODO: trigger orders here
	orders_page.hide()
	active_order_page.show()

func _on_orders_map_close_requested():
	order_map.hide()
