extends VBoxContainer

func _ready() -> void:
	display_scores()

func display_scores() -> void:
	# Remove only previously generated score labels.
	for child in get_children():
		if child.name.begins_with("ScoreEntry"):
			child.queue_free()

	for i in range(5):
		var score_label := Label.new()
		score_label.name = "ScoreEntry%d" % i
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 40)

		if i < LeaderboardManager.scores.size():
			score_label.text = "%d. %d" % [
				i + 1,
				LeaderboardManager.scores[i]
			]
		else:
			score_label.text = "%d. ---" % (i + 1)

		add_child(score_label)
