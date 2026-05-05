extends Area2D

const LevelCompleteUI = preload("res://scenes/ui/LevelCompleteUI.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var success_sfx: AudioStreamPlayer2D = $success_sfx
@onready var _goal_label: Label = $GoalLabel

var unlocked := false

func _ready() -> void:
	GameManager.all_coins_collected.connect(_unlock)
	body_entered.connect(_on_body_entered)
	sprite.play("closed")

func _unlock() -> void:
	unlocked = true
	sprite.play("open")
	_goal_label.modulate = Color.WHITE
	_pulse_label()

func _pulse_label() -> void:
	while is_instance_valid(self) and unlocked:
		var tween := create_tween()
		tween.tween_property(_goal_label, "scale", Vector2(1.2, 1.2), 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_goal_label, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
		await tween.finished

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and unlocked:
		GameManager.complete_level()
		if not success_sfx.playing:
			success_sfx.play()
		await get_tree().create_timer(0.4).timeout
		var ui := LevelCompleteUI.instantiate()
		get_tree().current_scene.add_child(ui)
