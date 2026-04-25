extends CharacterBody2D

const SPEED := 130.0
const JUMP_VELOCITY := -320.0
const ATTACK_DAMAGE := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

var is_attacking := false

func _ready() -> void:
	attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")

	if not is_attacking:
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
	if is_attacking:
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
