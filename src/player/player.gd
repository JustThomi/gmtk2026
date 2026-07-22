extends CharacterBody3D

@onready var model: Node3D = $Model

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

func _ready():
	print("aia zic coaie")

func _process(_delta):
	if position.y < -20:
		get_tree().reload_current_scene()

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var rotation_direction = Vector2(velocity.x, velocity.z).angle()
	model.rotation.y = lerp_angle(model.rotation.y, rotation_direction, delta * 10)

	move_and_slide()
