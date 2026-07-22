extends Control

@onready var phone: MarginContainer = $Phone

func _on_area_2d_mouse_entered():
	phone.position.y = 392.0

func _on_area_2d_mouse_exited():
	phone.position.y = 500.0
