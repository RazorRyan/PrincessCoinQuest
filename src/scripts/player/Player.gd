extends CharacterBody2D

const SPEED := 130.0
const JUMP_VELOCITY := -320.0
const ATTACK_DAMAGE := 1
const KNOCKBACK_FORCE := 160.0
const INVINCIBILITY_DURATION := 0.4

@export var max_hp := 3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

var hp: int
var is_attacking := false
var is_invincible := false
var is_hurt := false
var is_dying := false

func _ready() -> void:
	hp = max_hp
	attack_area.monitoring = false

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

		if Input.is_action_just_pressed("attack"):
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
	sprite.play("attack")
	attack_area.monitoring = true

	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)

	await get_tree().create_timer(0.25).timeout
	attack_area.monitoring = false
	is_attacking = false

func take_damage(amount: int, from_position: Vector2) -> void:
	if is_invincible or is_dying:
		return

	hp -= amount
	is_invincible = true
	is_hurt = true

	var knockback_dir := (global_position - from_position).normalized()
	velocity = knockback_dir * KNOCKBACK_FORCE

	sprite.play("hurt")

	if hp <= 0:
		die()
		return

	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_invincible = false
	is_hurt = false

func die() -> void:
	is_dying = true
	velocity = Vector2.ZERO
	sprite.play("die")
	await get_tree().create_timer(1.0).timeout
	GameManager.restart_level()
