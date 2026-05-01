extends Control

const FRAMES: Array[String] = [
	"res://assets/backgrounds/Intro_Movie_1.png",
	"res://assets/backgrounds/Intro_Movie_2.png",
	"res://assets/backgrounds/Intro_Movie_3.png",
	"res://assets/backgrounds/Intro_Movie_4.png",
	"res://assets/backgrounds/Intro_Movie_5.png",
	"res://assets/backgrounds/Intro_Movie_6.png",
	"res://assets/backgrounds/Intro_Movie_7.png",
]

# Duration each frame stays visible (full seconds, excluding fade time)
const FRAME_DURATIONS: Array[float] = [7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 0.0]
const FADE_DURATION := 0.5

@onready var movie_image: TextureRect = $MovieImage
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var skip_label: Label = $SkipLabel
@onready var intro_music: AudioStreamPlayer = $IntroMusic

var _current_frame := 0
var _on_last_frame := false
var _waiting_for_input := false

func _ready() -> void:
	fade_overlay.color = Color(0, 0, 0, 1)
	movie_image.scale = Vector2.ONE
	skip_label.modulate.a = 0.0
	intro_music.play(0.0)
	_play_sequence()

func _input(event: InputEvent) -> void:
	if not _waiting_for_input:
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		_load_first_level()

# ── Main sequence ─────────────────────────────────────────────────────────────

func _play_sequence() -> void:
	while _current_frame < FRAMES.size():
		# Load and display the frame
		_set_frame_image(_current_frame)
		_on_last_frame = _current_frame == FRAMES.size() - 1

		# Fade IN: overlay goes from black (alpha=1) → transparent (alpha=0), revealing image
		await _fade(0.0, FADE_DURATION)

		# Last frame: no label — just wait for a click
		if _on_last_frame:
			_waiting_for_input = true
			return  # Stop loop — input handler takes over

		# Wait while visible
		var wait_time: float = FRAME_DURATIONS[_current_frame]
		await get_tree().create_timer(wait_time).timeout

		# Fade OUT: overlay goes from transparent (alpha=0) → black (alpha=1)
		await _fade(1.0, FADE_DURATION)
		_current_frame += 1

	_load_first_level()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_frame_image(index: int) -> void:
	movie_image.texture = load(FRAMES[index])
	movie_image.scale = Vector2.ONE

func _fade(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", target_alpha, duration)
	await tween.finished

func _fade_label(label: Label, target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", target_alpha, duration)
	await tween.finished


func _load_first_level() -> void:
	# Fade out music and overlay simultaneously
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_property(intro_music, "volume_db", -80.0, FADE_DURATION)
	await tween.finished
	intro_music.stop()
	GameManager.start_game()
