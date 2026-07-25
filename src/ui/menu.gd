extends Control

@export var game_scene: PackedScene

func _on_play_button_pressed():
	get_tree().change_scene_to_packed(game_scene)

func _on_controlls_pressed():
	pass # Replace with function body.

func _on_exit_button_pressed():
	get_tree().quit()
