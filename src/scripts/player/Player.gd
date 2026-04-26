extends CharacterBody2D

const SPEED := 130.0
const JUMP_VELOCITY := -320.0
const ATTACK_DAMAGE := 1
const KNOCKBACK_FORCE := 160.0
const INVINCIBILITY_DURATION := 0.4
const ATTACK_COOLDOWN := 0.45

@export var max_hp := 3

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

func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	floor_snap_length = 8.0
	hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	if is_dying:
		move_and_slide()
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
		body.take_damage(ATTACK_DAMAGE)

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_dying:
		return

	hp -= amount
	is_invincible = true
	is_hurt = true
	hp_changed.emit(hp, max_hp)

	if from_position != Vector2.ZERO:
		var knockback_dir := (global_position - from_position).normalized()
		velocity = knockback_dir * KNOCKBACK_FORCE

	sprite.play("hurt")
	_hurt_sfx.play()
	_start_hurt_flash()

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
	sprite.modulate = Color.WHITE

func die() -> void:
	is_dying = true
	velocity = Vector2.ZERO
	sprite.play("die")
	_lose_sfx.play()
	await get_tree().create_timer(1.0).timeout
	GameManager.restart_level()
