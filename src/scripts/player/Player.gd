extends CharacterBody2D

const SPEED := 160.0
const JUMP_VELOCITY := -400.0
const ATTACK_DAMAGE := 1
const KNOCKBACK_FORCE := 120.0
const INVINCIBILITY_DURATION := 0.5
const ATTACK_COOLDOWN := 0.45

@export var max_hp := 3
@export var fall_death_y := 400.0

signal hp_changed(current: int, maximum: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var _jump_sfx: AudioStreamPlayer = $jump_sfx
@onready var _hurt_sfx: AudioStreamPlayer = $hurt_sfx
@onready var _attack_sfx: AudioStreamPlayer = $attack_sfx
@onready var _lose_sfx: AudioStreamPlayer = $lose_sfx

var hp: int
var is_attacking := false
var is_invincible := false
var is_hurt := false
var is_dying := false
var can_attack := true
var _attack_hits := {}

var _power_up_active := false
var _power_up_timer := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	floor_snap_length = 8.0
	hp_changed.emit(hp, max_hp)

func activate_invincibility() -> void:
	_power_up_active = true
	_power_up_timer = 10.0
	sprite.modulate = Color(1.0, 1.0, 0.4, 1.0)
	_set_music_pitch(1.3)

func _set_music_pitch(pitch: float) -> void:
	for node in get_tree().get_nodes_in_group("music_players"):
		if node is AudioStreamPlayer:
			node.pitch_scale = pitch
			return
	# Fallback: search all AudioStreamPlayer nodes on the Music bus
	_find_and_set_pitch(get_tree().root, pitch)

func _find_and_set_pitch(node: Node, pitch: float) -> void:
	if node is AudioStreamPlayer and node.bus == &"Music":
		node.pitch_scale = pitch
		return
	for child in node.get_children():
		_find_and_set_pitch(child, pitch)

func _physics_process(delta: float) -> void:
	if _power_up_active:
		_power_up_timer -= delta
		if _power_up_timer <= 0.0:
			_power_up_active = false
			sprite.modulate = Color.WHITE
			_set_music_pitch(1.0)

	if is_dying:
		move_and_slide()
		return

	if global_position.y > fall_death_y:
		die()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")

	if not is_attacking and not is_hurt and not is_dying:
		velocity.x = direction * SPEED

		if direction != 0:
			sprite.flip_h = direction < 0
			attack_area.scale.x = -1 if direction < 0 else 1

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			_jump_sfx.play()

		if Input.is_action_just_pressed("attack") and can_attack:
			attack()

	move_and_slide()
	update_animation(direction)

func update_animation(direction: float) -> void:
	if is_attacking or is_hurt or is_dying:
		return

	if not is_on_floor():
		sprite.play("jump")
	elif direction != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

func attack() -> void:
	is_attacking = true
	can_attack = false
	_attack_hits.clear()
	sprite.play("attack")
	_attack_sfx.play()
	attack_area.monitoring = true

	await get_tree().create_timer(0.25).timeout
	attack_area.monitoring = false
	is_attacking = false

	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if is_attacking and not body in _attack_hits and body.has_method("take_damage"):
		_attack_hits[body] = true
		body.take_damage(ATTACK_DAMAGE, global_position)

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if _power_up_active or is_invincible or is_dying or GameManager.cheat_invincible:
		return

	hp -= amount
	is_invincible = true
	is_hurt = true
	hp_changed.emit(hp, max_hp)

	if from_position != Vector2.ZERO:
		var knockback_dir := (global_position - from_position).normalized()
		velocity.x = knockback_dir.x * KNOCKBACK_FORCE
		velocity.y = -55.0

	sprite.play("hurt")
	_hurt_sfx.play()
	_start_hurt_flash()
	shake_camera(4.0, 0.15)

	if hp <= 0:
		die()
		return

	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_invincible = false
	is_hurt = false

func _start_hurt_flash() -> void:
	var flash_interval := 0.07
	var flashes := int(INVINCIBILITY_DURATION / (flash_interval * 2))
	for i in flashes:
		sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)
		await get_tree().create_timer(flash_interval).timeout
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.4)
		await get_tree().create_timer(flash_interval).timeout
	if not _power_up_active:
		sprite.modulate = Color.WHITE

func shake_camera(amount := 3.0, duration := 0.15) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var elapsed := 0.0
	while elapsed < duration:
		var t := 1.0 - (elapsed / duration)
		cam.offset = Vector2(
			randf_range(-amount, amount) * t,
			randf_range(-amount, amount) * t
		)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	cam.offset = Vector2.ZERO

func die() -> void:
	is_dying = true
	velocity = Vector2.ZERO
	sprite.play("die")
	_lose_sfx.play()
	await get_tree().create_timer(1.0).timeout
	GameManager.restart_level()
