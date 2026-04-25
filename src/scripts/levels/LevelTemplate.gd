extends Node2D

@onready var coins_container: Node = $Coins

func _ready() -> void:
	var total := coins_container.get_child_count()
	GameManager.reset_level_coin_count(total)
