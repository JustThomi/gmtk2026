extends Node

const SAVE_PATH := "user://leaderboard.json"
const MAX_SCORES := 5

var scores: Array[int] = []

func _ready() -> void:
	load_scores()

func add_current_score() -> void:
	add_score(OrderManager.points)

func add_score(score: int) -> void:
	scores.append(score)

	scores.sort()
	scores.reverse()

	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)

	save_scores()

func save_scores() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Could not save leaderboard.")
		return

	file.store_string(JSON.stringify(scores))

func load_scores() -> void:
	scores.clear()

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not load leaderboard.")
		return

	var parsed_data = JSON.parse_string(file.get_as_text())

	if parsed_data is Array:
		for value in parsed_data:
			scores.append(int(value))

		scores.sort()
		scores.reverse()

		if scores.size() > MAX_SCORES:
			scores.resize(MAX_SCORES)

func clear_scores() -> void:
	scores.clear()
	save_scores()
