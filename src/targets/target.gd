extends Area3D

@export var type: Types
@export var rotation_speed := 5.0

@onready var npc: Node3D = $Greeter
@onready var animation_player: AnimationPlayer = $Greeter/AnimationPlayer
@onready var collider: CollisionShape3D = $CollisionShape3D

var player = null
var is_active := false

enum Types {
	restaurant,
	house
}

func enable(p: Node3D):
	player = p
	
	collider.disabled = false
	start_emote()
	show()

func _process(_delta):
	if !is_active or player == null:
		return

	var target_pos = player.global_position
	target_pos.y = npc.global_position.y

	var desired = atan2(
		target_pos.x - npc.global_position.x,
		target_pos.z - npc.global_position.z
	)

	npc.rotation.y = lerp_angle(
		npc.rotation.y,
		desired,
		rotation_speed * _delta
	)

func disable():
	collider.disabled = true
	stop_emote()
	hide()

func _ready():
	disable()

func _on_player_area_entered(_area: Area3D) -> void:
	if type == Types.restaurant:
		OrderManager.order_picked_up()
	else:
		OrderManager.order_finished()
	
	$CollisionShape3D.disabled = true

func start_emote():
	is_active = true
	if animation_player.has_animation("interact-right"):
		animation_player.play("interact-right")

func stop_emote():
	is_active = false
	animation_player.stop()
