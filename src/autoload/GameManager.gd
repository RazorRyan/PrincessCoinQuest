extends Node

var coins_collected: int = 0
var total_coins: int = 0
var current_level: int = 1

signal coins_changed(current: int, total: int)
signal all_coins_collected

func reset_level_coin_count(total: int) -> void:
	coins_collected = 0
	total_coins = total
	coins_changed.emit(coins_collected, total_coins)

func collect_coin() -> void:
	coins_collected += 1
	coins_changed.emit(coins_collected, total_coins)

	if coins_collected >= total_coins:
		all_coins_collected.emit()

func go_to_next_level() -> void:
	current_level += 1
	var next_level_path := "res://scenes/levels/Level%02d.tscn" % current_level

	if ResourceLoader.exists(next_level_path):
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("No more levels. Game complete.")
