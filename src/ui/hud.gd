extends Control

@onready var phone: MarginContainer = $Phone

@onready var orders_page: MarginContainer = $Phone/OrdersPage
@onready var active_order_page: MarginContainer = $Phone/ActiveOrderPage

@onready var distance_value: Label = $Phone/ActiveOrderPage/MenuContainer/DistanceValue

@onready var order_map: Window = $OrdersMap

func _ready() -> void:
	#orders_page.show()
	#active_order_page.hide()
	
	orders_page.hide()
	active_order_page.show()
	
	order_map.hide()

func _process(_delta: float) -> void:
	if OrderManager.current_target != null:
		distance_value.text = str(int(OrderManager.distance))

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
