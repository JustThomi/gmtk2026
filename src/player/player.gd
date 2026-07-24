extends CharacterBody3D

# @onready var model: Node3D = $Model
@onready var arrow: Node3D = $Arrrow
@onready var visual_root: Node3D = $VisualRoot
@onready var anim = $VisualRoot/RiderMount/Rider/AnimationPlayer
@onready var backpack: Node3D = $VisualRoot/Backpack

@export var wheelie_angle: float = 30.0
@export var wheelie_speed: float = 8.0
@export var wheelie_lift_height = 0.75
@export var model_rotation_offset := deg_to_rad(-45.0)
@export var hud: Control
@export var spin_speed: float = 10.0

const SPEED = 20.0
const JUMP_VELOCITY = 15
var default_pivot_y: float
var wheelie_direction := Vector3.ZERO
var is_wheelie := false
var last_wall_collision : int = 0
var cooldown_ms : int = 2000   

func _ready():
	default_pivot_y = visual_root.position.y
	OrderManager.order_picked.connect(_on_order_picked_up)
	OrderManager.order_completed.connect(_on_order_completed)
	set_backpack_active(false)

func _process(_delta):
	if position.y < -20:
		get_tree().reload_current_scene()
	
	if OrderManager.current_target != null:
		arrow.look_at(OrderManager.current_target.global_position)

func _physics_process(delta):
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var spin_input = Input.get_axis("spinLeft", "spinRight")
	var is_spinning = not is_on_floor() and spin_input != 0
	
	if is_spinning:
		input_dir = Vector2.ZERO
		
	var input_direction := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
		
		if is_spinning:
			visual_root.rotate_y(-spin_input * spin_speed * delta)
		
	if Input.is_action_just_pressed("orders"):
		hud.order_map.visible = not hud.order_map.visible

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var target_pitch: float = 0.0
	var target_y: float = default_pivot_y	
	if Input.is_action_pressed("wheelie") and is_on_floor():
		target_pitch = deg_to_rad(wheelie_angle)
		target_y = default_pivot_y + wheelie_lift_height

	visual_root.rotation.x = lerp(visual_root.rotation.x, target_pitch, wheelie_speed * delta)
	visual_root.position.y = lerp(visual_root.position.y, target_y, wheelie_speed * delta)

	if input_direction.length_squared() > 0.0:
		input_direction = input_direction.normalized()

	if Input.is_action_just_pressed("wheelie"):
		is_wheelie = true
		var current_movement := Vector3(velocity.x, 0.0, velocity.z)
		if current_movement.length_squared() > 0.0:
			wheelie_direction = current_movement.normalized()
		elif input_direction.length_squared() > 0.0:
			wheelie_direction = input_direction

	if Input.is_action_just_released("wheelie"):
		is_wheelie = false

	var movement_direction := input_direction

	if is_wheelie:
		movement_direction = wheelie_direction

	if movement_direction.length_squared() > 0.0:
		var current_speed := SPEED

		if is_wheelie:
			anim.play("wheelie")
			current_speed *= 1.5
		else:
			anim.play("ride_pose")
		
		velocity.x = movement_direction.x * current_speed
		velocity.z = movement_direction.z * current_speed

		

		var target_rotation := atan2(-movement_direction.x, -movement_direction.z)
		target_rotation += model_rotation_offset

		if not is_spinning:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rotation, delta * 10.0)
	else:
		anim.stop()
		
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if is_on_wall() and OrderManager.is_order_picked:		
		var current_time = Time.get_ticks_msec()
		
		if current_time - last_wall_collision < cooldown_ms:
			return
		
		last_wall_collision = current_time
		print("The bike hit a wall" + str(current_time))
		OrderManager.damage_package()	

func set_backpack_active(active: bool) -> void:
	backpack.visible = active

func _on_order_picked_up():
	set_backpack_active(true)

func _on_order_completed():
	set_backpack_active(false)
