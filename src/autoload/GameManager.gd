extends Node

var coins_collected: int = 0
var total_coins: int = 0
var current_level_index: int = 0
var cheat_invincible: bool = false

var current_checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint := false

var levels: Array[String] = [
	"res://scenes/levels/forest_levels/Level01.tscn",
	"res://scenes/levels/forest_levels/Level02.tscn",
	"res://scenes/levels/forest_levels/Level03.tscn",
	"res://scenes/levels/forest_levels/BossLevel.tscn",
]

signal coins_changed(current: int, total: int)
signal all_coins_collected
signal level_completed

func reset_level_coin_count(total: int) -> void:
	coins_collected = 0
	total_coins = total
	coins_changed.emit(coins_collected, total_coins)

func collect_coin() -> void:
	coins_collected += 1
	coins_changed.emit(coins_collected, total_coins)

	if coins_collected >= total_coins:
		all_coins_collected.emit()

func complete_level() -> void:
	level_completed.emit()

func start_game() -> void:
	coins_collected = 0
	total_coins = 0
	current_level_index = 0
	get_tree().change_scene_to_file(levels[0])

func has_next_level() -> bool:
	return current_level_index + 1 < levels.size()

func restart_level() -> void:
	coins_collected = 0
	clear_checkpoint()
	get_tree().change_scene_to_file(levels[current_level_index])

func go_to_next_level() -> void:
	var next_index := current_level_index + 1
	clear_checkpoint()
	if next_index < levels.size():
		current_level_index = next_index
		get_tree().change_scene_to_file(levels[current_level_index])
	else:
		print("No more levels. Game complete.")

func load_level_at_index(index: int) -> void:
	coins_collected = 0
	total_coins = 0
	current_level_index = index
	clear_checkpoint()
	get_tree().change_scene_to_file(levels[index])

func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint_position = pos
	has_checkpoint = true

func get_respawn_position(fallback: Vector2) -> Vector2:
	if has_checkpoint:
		return current_checkpoint_position
	return fallback

func clear_checkpoint() -> void:
	has_checkpoint = false
	current_checkpoint_position = Vector2.ZERO
