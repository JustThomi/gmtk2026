extends AudioStreamPlayer

@export var fade_duration : float = 1.5
var target_volume : float = 0.0
var current_playlist : Array[AudioStream] = []

func _ready():
	bus = "Music"
	volume_db = -80.0
	finished.connect(_play_next_in_playlist)

func play_music(new_playlist: Array[AudioStream]):
	if current_playlist == new_playlist and playing:
		return
	
	current_playlist = new_playlist
	
	if playing:
		var fade_out = create_tween()
		fade_out.tween_property(self, "volume_db", -80.0, fade_duration)
		await fade_out.finished
		stop()
	
	if current_playlist.size() > 0:
		_play_next_in_playlist()

func set_music_volume(linear_value: float):
	var bus_index := AudioServer.get_bus_index("Music")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func _play_next_in_playlist():
	stream = current_playlist[randi() % current_playlist.size()]
	play()
	
	volume_db = -80.0
	var fade_in = create_tween()
	fade_in.tween_property(self, "volume_db", target_volume, fade_duration)
