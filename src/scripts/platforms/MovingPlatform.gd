extends AnimatableBody2D

## Polished moving platform.
## Travels between StartPoint and EndPoint (both Marker2D children).
## StartPoint is the platform's spawn position (local 0,0).
## EndPoint offset defines travel direction and distance.
## Bob is visual-only — physics position is clean for reliable floor detection.

@export var speed     := 40.0   ## pixels per second
@export var wait_time := 0.5    ## pause at each end in seconds
@export var bob_amount := 1.5   ## visual oscillation amplitude in pixels

@onready var _visual: Node2D  = $Visual
@onready var _start:  Marker2D = $StartPoint
@onready var _end:    Marker2D = $EndPoint

var _start_pos:    Vector2
var _end_pos:      Vector2
var _travel_pos:   Vector2   # authoritative physics position (no bob)
var _going_to_end: bool = true
var _waiting:      bool = false
var _bob_time:     float = 0.0

func _ready() -> void:
	# Cache world positions before any movement.
	# Since markers are children they will move with us, so we read them once now.
	_start_pos  = _start.global_position
	_end_pos    = _end.global_position
	_travel_pos = _start_pos
	global_position = _start_pos

func _physics_process(delta: float) -> void:
	# --- Travel ---
	if not _waiting:
		var target     := _end_pos if _going_to_end else _start_pos
		var to_target  := target - _travel_pos
		var dist       := to_target.length()

		if dist <= speed * delta:
			_travel_pos    = target
			_waiting       = true
			_going_to_end  = not _going_to_end
			get_tree().create_timer(wait_time).timeout.connect(
				_on_wait_done, CONNECT_ONE_SHOT
			)
		else:
			_travel_pos += to_target.normalized() * speed * delta

	# Physics body uses clean position (no bob) — ensures get_floor_velocity()
	# is stable and doesn't jitter the player.
	global_position = _travel_pos

	# --- Visual bob (cosmetic only, does not affect collision) ---
	_bob_time += delta * 2.5
	_visual.position.y = sin(_bob_time) * bob_amount

func _on_wait_done() -> void:
	_waiting = false
