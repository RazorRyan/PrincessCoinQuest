extends CanvasLayer

@onready var health_bar: ProgressBar = $TopBar/HealthBar
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	_update_level_label()
	call_deferred("_connect_player")

func _connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		await get_tree().process_frame
		_connect_player()
		return
	var player := players[0]
	if not player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.connect(_on_player_hp_changed)
	_on_player_hp_changed(player.hp, player.max_hp)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_toggle_pause()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused

func _update_level_label() -> void:
	level_label.text = "Level %d" % (GameManager.current_level_index + 1)

func _on_coins_changed(current: int, total: int) -> void:
	coin_label.text = "Coins: %d / %d" % [current, total]

func _on_player_hp_changed(current: int, maximum: int) -> void:
	health_bar.value = float(current) / float(maximum)

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	GameManager.restart_level()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	get_tree().change_scene_to_file("res://scenes/levels/MainMenu.tscn")
