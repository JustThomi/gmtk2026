extends CharacterBody3D

# @onready var model: Node3D = $Model
@onready var arrow: Node3D = $Arrrow
@onready var visual_root: Node3D = $VisualRoot
@onready var anim = $VisualRoot/RiderMount/Rider/AnimationPlayer
@onready var anim_tree = $VisualRoot/RiderMount/Rider/AnimationTree
@onready var spin_popup: Label3D = $VisualRoot/SpinPopup

@onready var backpack: Node3D = $VisualRoot/Backpack
@onready var bikes : Array[Node3D] = [$VisualRoot/RedBike, $VisualRoot/MountainBike, $VisualRoot/Unicycle]
@onready var rider_mount: Node3D = $VisualRoot/RiderMount
@onready var upgrade_window = $"../HUD/UpgradeWindow"

@export var wheelie_angle: float = 30.0
@export var wheelie_speed: float = 8.0
@export var wheelie_lift_height = 0.75
@export var model_rotation_offset := deg_to_rad(-45.0)
@export var hud: Control
@export var spin_speed: float = 10.0
@export var dry_acceleration := 100.0
@export var rain_acceleration := 18.0
@export var dry_deceleration := 100.0
@export var rain_deceleration := 8.0

const SPEED = 20.0
const JUMP_VELOCITY = 12
const RIDER_Y_OFFSET := -2.0

var unlocked_bikes: Array[bool] = [true, false, false]
var default_pivot_y: float
var wheelie_direction := Vector3.ZERO
var is_wheelie := false
var last_wall_collision : int = 0
var cooldown_ms : int = 2000
var current_bike := 0
var accumulated_spin: float = 0.0
var was_in_air: bool = false
var popup_base_y: float = 2.5
var spins_nr : int = 0

func _ready():
	default_pivot_y = visual_root.position.y
	OrderManager.order_picked.connect(_on_order_picked_up)
	OrderManager.order_completed.connect(_on_order_completed)
	switch_bike(0)
	upgrade_window.bike_bought.connect(_on_bike_bought)
	set_backpack_active(false)
	if spin_popup:
		popup_base_y = spin_popup.position.y
		spin_popup.modulate.a = 0.0
		spin_popup.outline_modulate.a = 0.0

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
		accumulated_spin += abs(-spin_input * spin_speed * delta)
		input_dir = Vector2.ZERO
		
	var input_direction := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if not is_on_floor():
		was_in_air = true
		velocity += get_gravity() * delta * 2
		
		if is_spinning:
			anim_tree.set("parameters/Transition/transition_request", "spin")
			visual_root.rotate_y(-spin_input * spin_speed * delta)
	elif was_in_air:
		was_in_air = false
		var rotations: int = floori(accumulated_spin / TAU)
		if rotations > 0 and spins_nr < rotations:
			# +1 ca altfel faci *1 ca prostu
			OrderManager.bonus_money *= (rotations + 1)
			spins_nr = rotations;
			show_spin_multiplier(rotations) # Trigger the visual effect!
		accumulated_spin = 0.0
			
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	#if Input.is_action_just_pressed("orders"):
		#hud.order_map.visible = not hud.order_map.visible

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
			anim_tree.set("parameters/Transition/transition_request", "wheelie")
			# anim.play("wheelie")
			current_speed *= 1.5
		else:
			anim_tree.set("parameters/Transition/transition_request", "ride_pose")
			# anim.play("ride_pose")
		
		var target_velocity := movement_direction * current_speed

		var acceleration := dry_acceleration

		if WeatherManager.current_weather == WeatherManager.Weather.RAIN \
		or WeatherManager.current_weather == WeatherManager.Weather.STORM:
			acceleration = rain_acceleration

		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

		var target_rotation := atan2(-movement_direction.x, -movement_direction.z)
		target_rotation += model_rotation_offset

		if not is_spinning:
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rotation, delta * 10.0)
	else:
		anim_tree.set("parameters/Transition/transition_request", "idle")
		
		if is_on_floor():
			var deceleration := dry_deceleration
			if WeatherManager.current_weather == WeatherManager.Weather.RAIN \
			or WeatherManager.current_weather == WeatherManager.Weather.STORM:
				deceleration = rain_deceleration

			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	move_and_slide()
	
	if is_on_wall() and OrderManager.is_order_picked:
		var current_time = Time.get_ticks_msec()
		
		if current_time - last_wall_collision < cooldown_ms:
			return
		
		last_wall_collision = current_time
		print("The bike hit a wall" + str(current_time))
		spins_nr = 0
		OrderManager.bonus_money = WeatherManager.get_payment_multiplier()
		OrderManager.damage_package()

func switch_bike(index: int) -> void:
	if index < 0 or index >= bikes.size():
		return

	if not unlocked_bikes[index]:
		return

	current_bike = index

	for bike in bikes:
		bike.visible = false

	var bike := bikes[index]
	bike.visible = true

	var seat: Node3D = bike.get_node("Seat")

	rider_mount.global_transform = seat.global_transform
	rider_mount.position.y += RIDER_Y_OFFSET

func _unhandled_input(event):
	if event.is_action_pressed("RedBike"):
		switch_bike(0)
	elif event.is_action_pressed("MountainBike"):
		switch_bike(1)
	elif event.is_action_pressed("Unicycle"):
		switch_bike(2)

func set_backpack_active(active: bool) -> void:
	backpack.visible = active

func _on_order_picked_up():
	set_backpack_active(true)

func _on_order_completed():
	set_backpack_active(false)

func _on_bike_bought(index: int) -> void:
	if index < 0 or index >= unlocked_bikes.size():
		return

	unlocked_bikes[index] = true

func show_spin_multiplier(rotations: int) -> void:
	spin_popup.text = "x" + str(rotations + 1) + " SPIN!"
	
	spin_popup.position.y = popup_base_y
	spin_popup.scale = Vector3.ZERO
	spin_popup.modulate.a = 1.0
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(spin_popup, "scale", Vector3(1, 1, 1), 0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(spin_popup, "position:y", popup_base_y + 1.0, 2.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(spin_popup, "modulate:a", 0.0, 0.5).set_delay(1.5)
