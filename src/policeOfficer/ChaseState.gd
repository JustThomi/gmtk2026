extends State

@export var stop_range : float = 1.0
@export var lose_interest_range : float = 25.0

var path_update_rate : float = 0.1
var last_path_update_time : float

func enter():
	super.enter()
	controller.is_stopped = true
	controller.is_running = false
	controller.look_at_player = true
	controller.is_playing_emote = true
	controller.set_alert_visible(true)
	
	for i in range(2):
		controller.anim_player.play("interact-left", -1.0, 1.5)
		await controller.anim_player.animation_finished
		if not active:
			return
	
	controller.is_playing_emote = false
	controller.is_stopped = false
	controller.is_running = true

func exit():
	super.exit()
	controller.is_running = false
	controller.look_at_player = false
	controller.set_alert_visible(false)

func update(delta):
	var current_time = Time.get_unix_time_from_system()
	
	if current_time - last_path_update_time > path_update_rate:
		last_path_update_time = current_time
		controller.move_to_position(controller.player.position, false)
	
	if controller.player_distance < stop_range:
		controller.is_stopped = true
	
	if controller.player_distance > lose_interest_range:
		state_machine.change_state("Patrol")
