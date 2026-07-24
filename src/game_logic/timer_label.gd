extends Label

@export var time_left: float

func _ready() -> void:
	timer_restart()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	time_left = time_left - 1

func timer_restart():
	time_left = 100
