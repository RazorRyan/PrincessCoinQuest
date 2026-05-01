extends Control

@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
	$ButtonContainer/StartGameButton.pressed.connect(_on_start_pressed)
	$ButtonContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$ButtonContainer/ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	music.stop()
	get_tree().change_scene_to_file("res://scenes/ui/IntroMovie.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
