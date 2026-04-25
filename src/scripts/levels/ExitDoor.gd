extends Area2D

var unlocked := false

func _ready() -> void:
	GameManager.all_coins_collected.connect(_unlock)
	body_entered.connect(_on_body_entered)

func _unlock() -> void:
	unlocked = true
	print("Exit unlocked!")

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and unlocked:
		GameManager.go_to_next_level()
