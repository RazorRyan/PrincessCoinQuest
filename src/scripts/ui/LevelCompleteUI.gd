extends CanvasLayer

func _ready() -> void:
	var replay_btn := $Panel/MarginContainer/VBoxContainer/ReplayButton
	var next_btn := $Panel/MarginContainer/VBoxContainer/NextLevelButton

	replay_btn.pressed.connect(_on_replay_pressed)
	next_btn.pressed.connect(_on_next_level_pressed)

	if not GameManager.has_next_level():
		next_btn.text = "GAME COMPLETE"
		next_btn.disabled = true

func _on_replay_pressed() -> void:
	GameManager.restart_level()

func _on_next_level_pressed() -> void:
	GameManager.go_to_next_level()
