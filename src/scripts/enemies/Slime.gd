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
	else:
		velocity.y = 0

	wall_check.target_position = Vector2(18 * direction, 0)
	floor_check.position.x = 12 * direction
	floor_check.target_position = Vector2(0, 24)
	
	print("wall:", wall_check.is_colliding(), " floor:", floor_check.is_colliding())

	if is_on_floor() and (wall_check.is_colliding() or not floor_check.is_colliding()):
		flip_direction()

	velocity.x = speed * direction
	move_and_slide()

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

func flip_direction() -> void:
	direction *= -1
	sprite.flip_h = direction > 0

func take_damage(amount: int) -> void:
	hp -= amount

	if hp <= 0:
		die()

func die() -> void:
	queue_free()
