extends AudioStreamPlayer

@export var playlist : Array[AudioStream] = []
@export var fade_duration : float = 2.0

var target_volume : float = 0.0

func _ready():
	volume_db = -80.0
	finished.connect(_on_finished)
	
	if playlist.size() > 0:
		play_next()

func play_next():
	if playing:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(self, "volume_db", -80.0, fade_duration)
		await fade_out_tween.finished
		stop()
	
	stream = playlist[randi() % playlist.size()]
	play()
	
	volume_db = -80.0
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(self, "volume_db", target_volume, fade_duration)

func _on_finished():
	play_next()
