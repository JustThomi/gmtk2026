extends Area3D

@export var type: Types

@onready var collider: CollisionShape3D = $CollisionShape3D

enum Types {
	restaurant,
	house
}

func enable():
	collider.disabled = false
	show()

func disable():
	collider.disabled = true
	hide()

func _ready():
	disable()

func _on_player_area_entered(_area: Area3D) -> void:
	if type == Types.restaurant:
		OrderManager.order_picked_up()
	else:
		OrderManager.order_finished()
	
	$CollisionShape3D.disabled = true
