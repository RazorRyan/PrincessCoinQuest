extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSound

var _pulse_time := 0.0
var _base_scale: Vector2

func _ready() -> void:
	_base_scale = sprite.scale
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 4.0) * 0.08
	sprite.scale = _base_scale * pulse

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.activate_invincibility()
		pickup_sfx.play()
		set_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		sprite.visible = false
		await pickup_sfx.finished
		queue_free()
