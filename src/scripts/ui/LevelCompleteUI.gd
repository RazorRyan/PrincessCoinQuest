extends CanvasLayer

func _ready() -> void:
	$Panel/MarginContainer/VBoxContainer/ReplayButton.pressed.connect(_on_replay_pressed)
	$Panel/MarginContainer/VBoxContainer/NextLevelButton.pressed.connect(_on_next_level_pressed)

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_level_pressed() -> void:
	pass
