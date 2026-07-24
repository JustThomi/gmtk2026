extends CharacterBody3D

# @onready var model: Node3D = $Model
@onready var arrow: Node3D = $Arrrow
@onready var visual_root: Node3D = $VisualRoot

@export var model_rotation_offset := deg_to_rad(-45.0)
@export var hud: Control

const SPEED = 20.0
const JUMP_VELOCITY = 4.5

func _ready():
	pass

func _process(_delta):
	if position.y < -20:
		get_tree().reload_current_scene()
	
	if OrderManager.current_target != null:
		arrow.look_at(OrderManager.current_target.global_position)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("orders"):
		hud.order_map.visible = not hud.order_map.visible

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var target_rotation := atan2(-direction.x, -direction.z)
		target_rotation += model_rotation_offset
		# model.rotation.y = lerp_angle(model.rotation.y, target_rotation, delta * 10)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rotation, delta * 10)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
