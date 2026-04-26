extends CharacterBody2D

@export var speed := 45.0
@export var hp := 2
@export var damage := 1
@export var knockback_force := 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck
@onready var hitbox: Area2D = $Hitbox

var direction := -1
var _flip_cooldown := 0.0
var _knockback_timer := 0.0
var _is_hurt := false
var _is_dying := false

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	wall_check.hit_from_inside = true

func _physics_process(delta: float) -> void:
	if _is_dying:
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	_flip_cooldown -= delta
	_knockback_timer -= delta

	if _knockback_timer <= 0.0:
		velocity.x = speed * direction

	move_and_slide()

	# Raycasts updated AFTER move_and_slide so position is fully resolved
	wall_check.position.x = 3 * direction
	wall_check.target_position = Vector2(6 * direction, 0)
	floor_check.position.x = 5 * direction
	wall_check.force_raycast_update()
	floor_check.force_raycast_update()


	if _flip_cooldown <= 0.0 and is_on_floor() and (_hit_wall_tile() or not floor_check.is_colliding()):
		flip_direction()
		_flip_cooldown = 0.5

	if not _is_hurt and not _is_dying:
		sprite.play("walk")

func _hit_wall_tile() -> bool:
	# Primary: is_on_wall() after move_and_slide — reliable, no scale issues
	if is_on_wall():
		for i in get_slide_collision_count():
			if not get_slide_collision(i).get_collider() is CharacterBody2D:
				return true
	# Fallback: raycast
	return wall_check.is_colliding() and not (wall_check.get_collider() is CharacterBody2D)

func flip_direction() -> void:
	direction *= -1
	sprite.flip_h = direction > 0

func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dying:
		return

	hp -= amount

	if _from_position != Vector2.ZERO:
		var dir := _from_position.direction_to(global_position)
		velocity.x = dir.x * knockback_force
		_knockback_timer = 0.25

	if hp <= 0:
		die()
	else:
		_play_hurt()

func _play_hurt() -> void:
	_is_hurt = true
	sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	if not _is_dying:
		_is_hurt = false

func die() -> void:
	_is_dying = true
	velocity = Vector2.ZERO
	sprite.play("die")
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
