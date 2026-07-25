extends Window

@onready var mountain_bike_model: Node3D = $MarginContainer/VBoxContainer/Bike/SubViewportContainer/SubViewport/mountain_bike
@onready var unicycle_model: Node3D = $MarginContainer/VBoxContainer/Bike2/SubViewportContainer/SubViewport/unicycle


func _process(_delta):
	spin_bikes()
	
	#if Input.is_action_just_pressed("orders"):
		#visible = not visible

func spin_bikes():
	mountain_bike_model.rotation_degrees.y += 1
	unicycle_model.rotation_degrees.y += 1

func _on_close_requested():
	hide()


func _on_mountain_bike_button_pressed():
	# TODO: change player model here
	$MarginContainer/VBoxContainer/Bike/Button.disabled = true
	hide()

func _on_unicycle_button_pressed():
	# TODO: change player model here
	$MarginContainer/VBoxContainer/Bike2/Button.disabled = true
	hide()
