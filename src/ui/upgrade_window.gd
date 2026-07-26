extends MarginContainer

@onready var mountain_bike_model: Node3D = $VBoxContainer/Mountain/SubViewport/mountain_bike
@onready var mountain_bike_cost_label = $VBoxContainer/Mountain/CostContainer/Cost
@onready var mountain_filter: ColorRect = $VBoxContainer/Mountain/SubViewport/Filter
@onready var mountain_money_logo: TextureRect = $VBoxContainer/Mountain/CostContainer/TextureRect

@onready var unicycle_model: Node3D = $VBoxContainer/Uni/SubViewport/unicycle
@onready var unicycle_cost_label = $VBoxContainer/Uni/CostContainer/Cost
@onready var unicycle_filter: ColorRect = $VBoxContainer/Uni/SubViewport/Filter
@onready var unicycle_money_logo: TextureRect = $VBoxContainer/Uni/CostContainer/TextureRect

@export var money_for_mountain_bike: int = 200
@export var money_for_unicycle: int = 150 

signal bike_bought(index: int)

func _process(_delta):
	spin_bikes()
	update_button_filter()

func update_button_filter():
	if mountain_filter.visible and unicycle_filter.visible:
		if OrderManager.money > int(mountain_bike_cost_label.text):
			mountain_filter.hide()
		if OrderManager.money > int(unicycle_cost_label.text):
			unicycle_filter.hide()

func spin_bikes():
	mountain_bike_model.rotation_degrees.y += 1
	unicycle_model.rotation_degrees.y += 1

func _on_mountain_button_pressed():
	if mountain_bike_cost_label.text == "Bought":
		OrderManager.player.switch_bike(1)
		
	elif OrderManager.money >= money_for_mountain_bike:
		OrderManager.money -= money_for_mountain_bike
		OrderManager.update_money_label()
		mountain_bike_cost_label.text = "Bought"
		mountain_money_logo.hide()
		bike_bought.emit(1)

func _on_uni_button_pressed():
	if unicycle_cost_label.text == "Bought":
		OrderManager.player.switch_bike(2)
		
	elif OrderManager.money >= money_for_unicycle:
		OrderManager.money -= money_for_unicycle
		OrderManager.update_money_label()
		unicycle_cost_label.text = "Bought"
		unicycle_money_logo.hide()
		bike_bought.emit(2)
