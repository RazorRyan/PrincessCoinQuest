extends CharacterBody2D

@export var speed := 45.0
@export var hp := 2
@export var damage := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck

var direction := -1

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = direction * speed

	if wall_check.is_colliding() or not floor_check.is_colliding():
		flip_direction()

	move_and_slide()
	sprite.play("walk")

func flip_direction() -> void:
	direction *= -1
	sprite.flip_h = direction > 0
	wall_check.scale.x *= -1
	floor_check.position.x *= -1

func take_damage(amount: int) -> void:
	hp -= amount
	sprite.play("hurt")

	if hp <= 0:
		die()

func die() -> void:
	queue_free()
