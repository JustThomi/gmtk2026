extends Node

#@onready var score_label: Label = $Panel/Score

#func _ready() -> void:
	#score_label.text = "Score: %d" % OrderManager.points

func _on_return_to_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/menu.tscn")
