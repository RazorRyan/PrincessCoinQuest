extends CharacterBody2D

const HealthBarScene := preload("res://scenes/ui/EnemyHealthBar.tscn")
const HitBurst := preload("res://scenes/effects/HitBurst.tscn")

@export var patrol_speed := 35.0
@export var chase_speed := 55.0
@export var hp := 10
@export var knockback_force := 60.0
@export var detection_range := 220.0
@export var stop_distance := 40.0
@export var attack_cooldown := 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_check: RayCast2D = $WallCheck
@onready var floor_check: RayCast2D = $FloorCheck
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _splat_sfx: AudioStreamPlayer2D = $splat_sfx
@onready var _hit_sfx: AudioStreamPlayer2D = $hit_sfx

var direction := -1
var _flip_cooldown := 0.0
var _knockback_timer := 0.0
var _is_hurt := false
var _is_dying := false
var _can_take_hit := true
var _can_attack := true
var _max_hp: int
var _health_bar: ProgressBar
var _splat_timer := 0.0
var _enraged := false
var _player: Node2D = null

func _ready() -> void:
	_max_hp = hp
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	wall_check.hit_from_inside = true
	_health_bar = HealthBarScene.instantiate()
	add_child(_health_bar)
	_splat_timer = randf_range(2.0, 4.0)

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

	_splat_timer -= delta
	if _splat_timer <= 0.0:
		_splat_sfx.play()
		_splat_timer = randf_range(2.0, 4.0)

	if _knockback_timer > 0.0 or _is_hurt:
		move_and_slide()
		return

	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

	if _player != null and is_instance_valid(_player):
		var dist := global_position.distance_to(_player.global_position)
		var dir_sign: float = sign(_player.global_position.x - global_position.x)

		if dist <= detection_range:
			if dir_sign != 0:
				direction = int(dir_sign)
			sprite.flip_h = direction > 0
			if dist > stop_distance:
				var spd := chase_speed * (1.5 if _enraged else 1.0)
				velocity.x = spd * dir_sign
			else:
				velocity.x = 0.0
		else:
			_do_patrol()
	else:
		_do_patrol()

	move_and_slide()

	wall_check.position.x = 3 * direction
	wall_check.target_position = Vector2(6 * direction, 0)
	floor_check.position.x = 5 * direction
	wall_check.force_raycast_update()
	floor_check.force_raycast_update()

	var is_patrolling := _player == null or not is_instance_valid(_player) \
		or global_position.distance_to(_player.global_position) > detection_range
	if is_patrolling and _flip_cooldown <= 0.0 and is_on_floor() \
			and (_hit_wall_tile() or not floor_check.is_colliding()):
		direction *= -1
		sprite.flip_h = direction > 0
		_flip_cooldown = 0.5

	if not _is_hurt and not _is_dying:
		_play_anim("walk")

func _do_patrol() -> void:
	var spd := patrol_speed * (1.5 if _enraged else 1.0)
	velocity.x = spd * direction

func _play_anim(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

func _hit_wall_tile() -> bool:
	if is_on_wall():
		for i in get_slide_collision_count():
			if not get_slide_collision(i).get_collider() is CharacterBody2D:
				return true
	return wall_check.is_colliding() and not (wall_check.get_collider() is CharacterBody2D)

func flip_direction() -> void:
	direction *= -1
	sprite.flip_h = direction > 0

func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dying or not _can_take_hit:
		return

	_can_take_hit = false
	hp -= amount

	if _from_position != Vector2.ZERO:
		var dir := _from_position.direction_to(global_position)
		velocity.x = dir.x * knockback_force
		velocity.y = -50.0
		_knockback_timer = 0.25

	if not _enraged and hp <= _max_hp / 2:
		_enraged = true
		sprite.modulate = Color(1.0, 0.5, 0.1)

	_update_health_bar()
	_spawn_hit_effects()

	if hp <= 0:
		die()
	else:
		_play_hurt()
		await get_tree().create_timer(0.25).timeout
		if not _is_dying:
			_can_take_hit = true

func _update_health_bar() -> void:
	_health_bar.value = float(hp) / float(_max_hp)
	_health_bar.visible = true

func _play_hurt() -> void:
	_is_hurt = true
	sprite.modulate = Color.WHITE
	_play_anim("hurt")
	await get_tree().create_timer(0.15).timeout
	if not _is_dying:
		sprite.modulate = Color(1.0, 0.5, 0.1) if _enraged else Color(0.6, 0.1, 0.9)
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
		players[0].shake_camera(5.0, 0.2)

func die() -> void:
	_is_dying = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	collision_shape.set_deferred("disabled", true)
	_play_anim("die")
	await get_tree().create_timer(1.2).timeout
	GameManager.all_coins_collected.emit()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("take_damage") and _can_attack:
		_can_attack = false
		body.take_damage(1, global_position)
		await get_tree().create_timer(attack_cooldown).timeout
		if not _is_dying:
			_can_attack = true
