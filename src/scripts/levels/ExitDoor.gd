extends Area2D

const LevelCompleteUI = preload("res://scenes/ui/LevelCompleteUI.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var success_sfx: AudioStreamPlayer2D = $success_sfx

var unlocked := false

func _ready() -> void:
	GameManager.all_coins_collected.connect(_unlock)
	body_entered.connect(_on_body_entered)
	sprite.play("closed")

func _unlock() -> void:
	unlocked = true
	sprite.play("open")

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and unlocked:
		GameManager.level_completed.emit()
		if not success_sfx.playing:
			success_sfx.play()
		await get_tree().create_timer(0.4).timeout
		var ui := LevelCompleteUI.instantiate()
		get_tree().current_scene.add_child(ui)
