extends Control

@export var game_scene: PackedScene

@onready var controlls_page: Control = $Controlls
@onready var main_page: Control = $Main

func _ready():
	main_page.show()
	controlls_page.hide()

func _on_play_button_pressed():
	get_tree().change_scene_to_packed(game_scene)

func _on_controlls_pressed():
	main_page.hide()
	controlls_page.show()

func _on_exit_button_pressed():
	get_tree().quit()

func _on_back_button_pressed():
	main_page.show()
	controlls_page.hide()
