extends CharacterBody3D

# @onready var model: Node3D = $Model
@onready var arrow: Node3D = $Arrrow
@onready var visual_root: Node3D = $VisualRoot
@onready var anim = $VisualRoot/RiderMount/Rider/AnimationPlayer
@onready var anim_tree = $VisualRoot/RiderMount/Rider/AnimationTree
@onready var spin_popup: Label3D = $VisualRoot/SpinPopup

@onready var backpack: Node3D = $VisualRoot/Backpack
@onready var bikes : Array[Node3D] = [$VisualRoot/RedBike, $VisualRoot/MountainBike, $VisualRoot/Unicycle]
@onready var colliders: Array[CollisionShape3D] = [$RedBikeCollider, $MountainBikeCollider, $UnicycleCollider]
@export var bike_speed_multipliers : Array[float] = [1.0, 1.0,  1.3 ]
@onready var rider_mount: Node3D = $VisualRoot/RiderMount
@onready var upgrade_window = $"../HUD/UpgradeWindow"

@export var wheelie_angle: float = 30.0
@export var wheelie_speed: float = 8.0
@export var wheelie_lift_height = 0.75
@export var model_rotation_offset := deg_to_rad(-45.0)
@export var hud: Control
@export var spin_speed: float = 10.0
@export var big_crash_speed: float = 15.0
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
var popup_tween: Tween

func _ready():
	default_pivot_y = visual_root.position.y
	OrderManager.order_picked.connect(_on_order_picked_up)
	OrderManager.order_completed.connect(_on_order_completed)
	OrderManager.combo_penalty.connect(_on_combo_penalty)
	switch_bike(0)
	upgrade_window.bike_bought.connect(_on_bike_bought)
	set_backpack_active(false)
	if spin_popup:
		popup_base_y = spin_popup.position.y
		spin_popup.modulate = Color("757dd9", 0.0)
		spin_popup.outline_modulate = Color(1.0, 1.0, 1.0, 0.0)
		spin_popup.outline_size = 24

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
		if rotations > 0:
			OrderManager.add_tricks(rotations)
			show_spin_multiplier(rotations, OrderManager.combo_multiplier)
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
		var current_speed := SPEED * bike_speed_multipliers[current_bike]

		if is_wheelie:
			anim_tree.set("parameters/Transition/transition_request", "wheelie")
			# anim.play("wheelie")
			current_speed *= 1.5
		else:
			anim_tree.set("parameters/Transition/transition_request", "ride_pose")
			# anim.play("ride_pose")
		
		var target_velocity := movement_direction * current_speed

		var acceleration := dry_acceleration

		if should_be_slippery():
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
			if should_be_slippery():
				deceleration = rain_deceleration

			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	move_and_slide()
	
	if is_on_wall():
		var current_time = Time.get_ticks_msec()
		
		if current_time - last_wall_collision < cooldown_ms:
			return
		
		last_wall_collision = current_time
		if _is_touching_police():
			OrderManager.register_police_bust()
			accumulated_spin = 0.0
			return
		var crash_speed := Vector3(velocity.x, 0.0, velocity.z).length()
		OrderManager.register_crash(crash_speed >= big_crash_speed)
		if OrderManager.is_order_picked:
			OrderManager.damage_package()
		accumulated_spin = 0.0

func _is_touching_police() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() is AIController:
			return true
	return false

func switch_bike(index: int) -> void:
	if index < 0 or index >= bikes.size():
		return

	if not unlocked_bikes[index]:
		return

	current_bike = index

	for bike in bikes:
		bike.visible = false

	for collider in colliders:
		collider.disabled = true
		colliders[index].disabled = false

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

func show_spin_multiplier(rotations: int, total_mult: float) -> void:
	var tier_word := "NICE!"
	var tier_color := Color("9be7ff")
	var pop_scale := 1.0
	if total_mult >= 7.0:
		tier_word = "INSANE!"
		tier_color = Color("ff4d6d")
		pop_scale = 1.6
	elif total_mult >= 5.0:
		tier_word = "SICK!"
		tier_color = Color("ff884d")
		pop_scale = 1.4
	elif total_mult >= 3.5:
		tier_word = "GNARLY!"
		tier_color = Color("ffcf4d")
		pop_scale = 1.25
	elif total_mult >= 2.0:
		tier_word = "RAD!"
		tier_color = Color("7dff9b")
		pop_scale = 1.1

	pop_scale = minf(pop_scale + (rotations - 1) * 0.08, 2.0)
	_play_popup("%s  x%.1f" % [tier_word, total_mult], tier_color, pop_scale)

func _on_combo_penalty(message: String, color: Color) -> void:
	_play_popup(message, color, 1.2)

func _play_popup(text: String, color: Color, pop_scale: float) -> void:
	if popup_tween and popup_tween.is_valid():
		popup_tween.kill()

	spin_popup.text = text
	spin_popup.position.y = popup_base_y
	spin_popup.scale = Vector3.ZERO
	spin_popup.modulate = Color(color, 1.0)
	spin_popup.outline_modulate = Color(1.0, 1.0, 1.0, 1.0)

	popup_tween = get_tree().create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(spin_popup, "scale", Vector3.ONE * pop_scale, 0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	popup_tween.tween_property(spin_popup, "modulate:a", 0.0, 0.5).set_delay(2.5)
	popup_tween.tween_property(spin_popup, "outline_modulate:a", 0.0, 0.5).set_delay(2.5)

func should_be_slippery() -> bool:
	var bad_weather := (
		WeatherManager.current_weather == WeatherManager.Weather.RAIN
		or WeatherManager.current_weather == WeatherManager.Weather.STORM
	)

	var is_mountain_bike := current_bike == 1

	return bad_weather and not is_mountain_bike
