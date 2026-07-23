extends Area3D

@export var type: Types

enum Types {
	restaurant,
	house
}

func _set_type(t: Types):
	type = t

func _on_player_area_entered(_area: Area3D) -> void:
	if type == Types.restaurant:
		OrderManager.order_picked_up()
	else:
		OrderManager.order_finished()
	
	$CollisionShape3D.disabled = true
