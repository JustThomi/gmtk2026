extends MarginContainer

@onready var mountain_bike_model: Node3D = $VBoxContainer/Mountain/SubViewportContainer/SubViewport/mountain_bike
@onready var unicycle_model: Node3D = $VBoxContainer/Uni/SubViewportContainer/SubViewport/unicycle
@onready var mountain_bike_cost_label = $VBoxContainer/Mountain/Cost
@onready var unicylce_cost_label = $VBoxContainer/Uni/Cost

@export var money_for_mountain_bike: int = 200
@export var money_for_unicycle: int = 150 

signal bike_bought(index: int)

func _process(_delta):
	spin_bikes()

func spin_bikes():
	mountain_bike_model.rotation_degrees.y += 1
	unicycle_model.rotation_degrees.y += 1

func _on_mountain_button_pressed():
	if(OrderManager.money >= money_for_mountain_bike):
		$MarginContainer/VBoxContainer/Bike/Button.disabled = true
		OrderManager.money -= money_for_mountain_bike
		OrderManager.update_money_label()
		mountain_bike_cost_label.text = "Bought"
		bike_bought.emit(1)

func _on_uni_button_pressed():
	if(OrderManager.money >= money_for_unicycle):
		$MarginContainer/VBoxContainer/Bike2/Button.disabled = true
		OrderManager.money -= money_for_unicycle
		OrderManager.update_money_label()
		unicylce_cost_label.text = "Bought"
		bike_bought.emit(2)
