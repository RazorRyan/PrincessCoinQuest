extends Control

func _ready() -> void:
	$ButtonContainer/Level1Button.pressed.connect(_on_level_pressed.bind(0))
	$ButtonContainer/Level2Button.pressed.connect(_on_level_pressed.bind(1))
	$ButtonContainer/Level3Button.pressed.connect(_on_level_pressed.bind(2))
	$ButtonContainer/BossLevelButton.pressed.connect(_on_level_pressed.bind(3))
	$ButtonContainer/BackButton.pressed.connect(_on_back_pressed)
	var toggle: CheckButton = $ButtonContainer/InvincibleToggle
	toggle.button_pressed = GameManager.cheat_invincible
	toggle.toggled.connect(_on_invincible_toggled)

func _on_level_pressed(index: int) -> void:
	GameManager.load_level_at_index(index)

func _on_invincible_toggled(enabled: bool) -> void:
	GameManager.cheat_invincible = enabled

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/MainMenu.tscn")
