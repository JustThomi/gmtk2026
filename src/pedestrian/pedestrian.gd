extends  CharacterBody3D

@export var walk_speed : float = 2
@export var max_wander_range : float = 20.0
@export var min_wait : float = 1.0
@export var max_wait : float = 5.0

@onready var agent : NavigationAgent3D = $"NavigationAgent3D"
@onready var anim_player : AnimationPlayer = $"character-female-b2/AnimationPlayer"
@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_waiting : bool = false
var is_knocked_down : bool = false

func _ready():
	rotation.y = randf_range(0, TAU)
	_pick_new_destination()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_knocked_down:
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
		move_and_slide()
		return
	
	if is_waiting:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	if agent.is_navigation_finished():
		_start_waiting()
		return
	
	var target_pos = agent.get_next_path_position()
	var move_dir = position.direction_to(target_pos)
	move_dir.y = 0
	move_dir = move_dir.normalized()
	
	velocity.x = move_dir.x * walk_speed
	velocity.z = move_dir.z * walk_speed
	
	if velocity.length() > 0.1:
		var target_y_rot = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_y_rot, 0.1)
		anim_player.play("walk")
	
	move_and_slide()

func _pick_new_destination():
	is_waiting = false
	
	var random_offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var target_point = position + (random_offset * randf_range(5.0, max_wander_range))
	var map = get_world_3d().navigation_map
	var adjusted_pos = NavigationServer3D.map_get_closest_point(map, target_point)
	
	agent.target_position = adjusted_pos

func _start_waiting():
	is_waiting = true
	anim_player.play("idle")
	
	var wait_time = randf_range(min_wait, max_wait)
	await  get_tree().create_timer(wait_time).timeout
	
	_pick_new_destination()


func _on_bump_detector_body_entered(body):
	if body.is_in_group("Player") and not is_knocked_down:
		knock_over(body)

func knock_over(body):
	is_knocked_down = true
	is_waiting = false
	
	var push_dir = (global_position - body.global_position).normalized()
	push_dir.y = 0
	
	velocity = push_dir * 5.0
	
	anim_player.play("die")
	await anim_player.animation_finished
	
	await get_tree().create_timer(2.0).timeout
	
	anim_player.play_backwards("die")
	await anim_player.animation_finished
	
	is_knocked_down = false
	_pick_new_destination()
