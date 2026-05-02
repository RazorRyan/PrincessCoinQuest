extends CharacterBody2D

const HealthBarScene := preload("res://scenes/ui/EnemyHealthBar.tscn")
const HitBurst := preload("res://scenes/effects/HitBurst.tscn")

@export var speed := 45.0
@export var hp := 1
@export var damage := 1
@export var knockback_force := 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck
@onready var hitbox: Area2D = $Hitbox
@onready var _splat_sfx: AudioStreamPlayer2D = $splat_sfx
@onready var _hit_sfx: AudioStreamPlayer2D = $hit_sfx

var direction := -1
var _flip_cooldown := 0.0
var _knockback_timer := 0.0
var _is_hurt := false
var _is_dying := false
var _max_hp: int
var _health_bar: ProgressBar
var _splat_timer := 0.0

func _ready() -> void:
	_max_hp = hp
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	wall_check.hit_from_inside = true
	_health_bar = HealthBarScene.instantiate()
	add_child(_health_bar)
	_splat_timer = randf_range(3.0, 6.0)

func _physics_process(delta: float) -> void:
	if _is_dying:
		move_and_slide()
		return

	_splat_timer -= delta
	if _splat_timer <= 0.0:
		_splat_sfx.play()
		_splat_timer = randf_range(3.0, 6.0)

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
		velocity.y = -50.0
		_knockback_timer = 0.25

	_update_health_bar()
	_spawn_hit_effects()
	if hp <= 0:
		die()
	else:
		_play_hurt()

func _update_health_bar() -> void:
	_health_bar.value = float(hp) / float(_max_hp)
	_health_bar.visible = true

func _play_hurt() -> void:
	_is_hurt = true
	sprite.modulate = Color(1, 0.4, 0.4)
	sprite.play("hurt")
	await get_tree().create_timer(0.15).timeout
	if not _is_dying:
		sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.15).timeout
	if not _is_dying:
		_is_hurt = false

func _spawn_hit_effects() -> void:
	_hit_sfx.play()
	var burst := HitBurst.instantiate()
	burst.global_position = global_position
	get_tree().current_scene.add_child(burst)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("shake_camera"):
		players[0].shake_camera(3.0, 0.12)

func die() -> void:
	_is_dying = true
	velocity = Vector2.ZERO
	sprite.play("die")
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
