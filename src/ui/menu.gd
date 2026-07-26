extends Control

@export var game_scene: PackedScene
@export var menu_songs : Array[AudioStream] = []

@onready var music_slider : HSlider = $Main/VSplitContainer/VBoxContainer/MusicSlider
@onready var controlls_page: Control = $Controlls
@onready var main_page: Control = $Main

func _ready():
	music_slider.value = 0.8
	MusicManager.set_music_volume(music_slider.value)
	
	main_page.show()
	controlls_page.hide()
	
	MusicManager.play_music(menu_songs)

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

func _on_music_slider_value_changed(value: float) -> void:
	MusicManager.set_music_volume(value)
