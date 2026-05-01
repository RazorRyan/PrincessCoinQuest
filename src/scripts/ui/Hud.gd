extends CanvasLayer

@onready var coin_label: Label = $CoinLabel
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
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

func _on_coins_changed(current: int, total: int) -> void:
	coin_label.text = "Coins: %d / %d" % [current, total]

func _on_player_hp_changed(current: int, maximum: int) -> void:
	health_bar.value = float(current) / float(maximum)
