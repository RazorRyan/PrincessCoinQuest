extends Node2D

@export var level_music: AudioStream = null
@export var music_loop_end: float = 60.0

@onready var coins_container: Node = $Coins if has_node("Coins") else null

var _music_player: AudioStreamPlayer

func _ready() -> void:
	var total := coins_container.get_child_count() if coins_container != null else 0
	GameManager.reset_level_coin_count(total)
	GameManager.level_completed.connect(_on_level_completed)
	_start_music()

func _on_level_completed() -> void:
	if _music_player and _music_player.playing:
		_music_player.pitch_scale = 1.0
		_music_player.stop()

func _start_music() -> void:
	if level_music == null:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = level_music
	_music_player.bus = &"Music"
	_music_player.add_to_group("music_players")
	add_child(_music_player)
	_music_player.play()
	var timer := Timer.new()
	timer.wait_time = music_loop_end
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_loop_timer_timeout)
	timer.start()

func _on_loop_timer_timeout() -> void:
	if _music_player:
		_music_player.stop()
		_music_player.play()
