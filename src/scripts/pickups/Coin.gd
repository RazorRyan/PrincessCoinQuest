extends Area2D

const CoinSparkle := preload("res://scenes/effects/CoinSparkle.tscn")

@onready var _pickup_sfx: AudioStreamPlayer2D = $PickupSound

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_spawn_pickup_effects()
		GameManager.collect_coin()
		queue_free()

func _spawn_pickup_effects() -> void:
	var sparkle := CoinSparkle.instantiate()
	sparkle.global_position = global_position
	get_tree().current_scene.add_child(sparkle)
	# Detach sound to scene so it survives queue_free
	var sfx := AudioStreamPlayer.new()
	sfx.stream = _pickup_sfx.stream
	sfx.bus = &"SFX"
	sfx.autoplay = true
	get_tree().current_scene.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
