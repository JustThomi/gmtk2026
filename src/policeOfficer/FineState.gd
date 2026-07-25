extends State

@export var fine_amount : float = 10.0
@export var fine_cooldown : float = 3.0


func enter():
	super.enter()
	
	OrderManager.apply_fine(fine_amount)
	OrderManager.register_police_bust()
	
	controller.is_stopped = true
	controller.is_running = false
	controller.look_at_player = true
	controller.is_playing_emote = true
	controller.set_fine_visible(true)
	
	controller.anim_player.play("interact-right", -1.0, 1.0)
	
	await get_tree().create_timer(fine_cooldown).timeout
	
	if not active:
		return
	
	state_machine.change_state("Patrol")

func exit():
	super.exit()
	controller.is_stopped = false
	controller.look_at_player = false
	controller.is_playing_emote = false
	controller.set_fine_visible(false)
