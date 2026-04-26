extends CharacterBody2D

@export var speed := 45.0
@export var hp := 2
@export var damage := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck
@onready var hitbox: Area2D = $Hitbox

var direction := -1

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	wall_check.position.x = 18 * direction
	wall_check.target_position = Vector2(18 * direction, 0)
	floor_check.position.x = 12 * direction

	if is_on_floor() and (_wall_hit() or not floor_check.is_colliding()):
		flip_direction()

	velocity.x = speed * direction
	move_and_slide()

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

func _wall_hit() -> bool:
	if not wall_check.is_colliding():
		return false
	return not (wall_check.get_collider() is CharacterBody2D)

func flip_direction() -> void:
	direction *= -1
	sprite.flip_h = direction > 0

func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	hp -= amount

	if hp <= 0:
		die()

func die() -> void:
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
