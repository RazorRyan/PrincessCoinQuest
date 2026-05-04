extends Area2D

## Damage dealt to the player on each hit.
@export var damage := 1
## Seconds between damage applications while player stands in lava.
@export var cooldown := 0.8

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_inside := false
var _damage_timer := 0.0
var _pulse_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_play_lava_animation()
	_sprite.frame_changed.connect(_pin_bottom)

func _pin_bottom() -> void:
	# Keep the base of the lava locked at the same y regardless of frame height.
	# Frame 0 is the shortest — taller frames extend upward from the same base.
	var frames := _sprite.sprite_frames
	if frames == null:
		return
	var anim := _sprite.animation
	var base_tex := frames.get_frame_texture(anim, 0)
	var cur_tex := frames.get_frame_texture(anim, _sprite.frame)
	if base_tex == null or cur_tex == null:
		return
	var base_h := float(base_tex.get_height())
	var cur_h := float(cur_tex.get_height())
	_sprite.offset.y = (base_h - cur_h) / 2.0

func _play_lava_animation() -> void:
	if _sprite.sprite_frames == null:
		return
	if _sprite.sprite_frames.has_animation(&"flow"):
		_sprite.play(&"flow")
	elif _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")

func _process(delta: float) -> void:
	# Damage tick while player is standing in lava.
	if _player_inside:
		if _damage_timer > 0.0:
			_damage_timer -= delta
		else:
			_deal_damage()

	# Subtle heat shimmer: pulse sprite alpha between 85% and 100%.
	_pulse_time += delta * 3.0
	var t := sin(_pulse_time) * 0.5 + 0.5
	_sprite.modulate.a = 0.85 + t * 0.15

func _deal_damage() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			_damage_timer = cooldown
			return

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_damage_timer = 0.0  # Damage on immediate contact.

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_damage_timer = 0.0
