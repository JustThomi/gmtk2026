extends Control

@onready var phone: MarginContainer = $Phone
@onready var orders_page: MarginContainer = $Phone/OrdersPage
@onready var active_order_page: MarginContainer = $Phone/ActiveOrderPage

func _ready() -> void:
	orders_page.show()
	active_order_page.hide()

func _on_mouse_detector_mouse_entered() -> void:
	phone.position.y = 392.0

func _on_mouse_detector_mouse_exited() -> void:
	phone.position.y = 500.0

func _on_order_button_pressed() -> void:
	# TODO: trigger orders here
	orders_page.hide()
	active_order_page.show()
