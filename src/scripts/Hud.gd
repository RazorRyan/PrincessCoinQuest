extends CanvasLayer

@onready var coin_label: Label = $CoinLabel

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(current: int, total: int) -> void:
	coin_label.text = "Coins: %d / %d" % [current, total]
