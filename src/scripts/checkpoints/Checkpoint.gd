extends Area2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite.play(&"inactive")

func _on_body_entered(body: Node) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activate()

func _activate() -> void:
	_activated = true
	GameManager.set_checkpoint(global_position)
	_sprite.play(&"active")
	if _sfx.stream != null:
		_sfx.play()
