extends CanvasLayer

## Mobile touch controls overlay.
##
## Multi-touch is handled by tracking each InputEventScreenTouch index so the
## player can hold LEFT and tap JUMP at the same time without either being
## cancelled.  The CanvasLayer.layer is set high so controls always draw on top.
##
## On desktop builds the overlay hides itself so it never interferes with
## keyboard or gamepad play.

@onready var _left_btn: TextureButton   = $Control/LeftButton
@onready var _right_btn: TextureButton  = $Control/RightButton
@onready var _jump_btn: TextureButton   = $Control/JumpButton
@onready var _attack_btn: TextureButton = $Control/AttackButton
@onready var _pause_btn: Button         = $Control/PauseButton
@onready var _debug_lbl: Label          = $Control/DebugLabel

## Maps touch finger index → input action name.
var _touch_map: Dictionary = {}

func _ready() -> void:
	# Hide on desktop unless emulate_touch_from_mouse is on (used for testing).
	var is_mobile: bool = OS.has_feature("mobile") or OS.has_feature("web")
	var emulate_touch: bool = ProjectSettings.get_setting(
			"input_devices/pointing/emulate_touch_from_mouse", false)
	if not (is_mobile or emulate_touch):
		visible = false
		return

	_pause_btn.add_theme_font_size_override("font_size", 28)
	# Pause button must respond even when the tree is paused.
	_pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_btn.pressed.connect(_on_pause_pressed)

	# Debug label only shows in editor / debug exports.
	_debug_lbl.visible = OS.is_debug_build()


func _exit_tree() -> void:
	# Release any held actions when the scene is unloaded (e.g. level change).
	for action: String in _touch_map.values():
		Input.action_release(action)
	_touch_map.clear()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event.index, event.position)
		else:
			_on_touch_up(event.index)


func _on_touch_down(touch_id: int, pos: Vector2) -> void:
	var map: Dictionary = {
		"move_left":  _left_btn,
		"move_right": _right_btn,
		"jump":       _jump_btn,
		"attack":     _attack_btn,
	}
	for action: String in map:
		var btn: TextureButton = map[action]
		if btn.get_global_rect().has_point(pos):
			_touch_map[touch_id] = action
			Input.action_press(action)
			_animate_press(btn)
			_update_debug()
			return


func _on_touch_up(touch_id: int) -> void:
	if not _touch_map.has(touch_id):
		return
	var action: String = _touch_map[touch_id]
	Input.action_release(action)
	_animate_release(_btn_for_action(action))
	_touch_map.erase(touch_id)
	_update_debug()


func _btn_for_action(action: String) -> TextureButton:
	match action:
		"move_left":  return _left_btn
		"move_right": return _right_btn
		"jump":       return _jump_btn
		"attack":     return _attack_btn
	return null


func _animate_press(btn: TextureButton) -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.06)
	btn.modulate = Color(1.0, 1.0, 0.7, 0.95)


func _animate_release(btn: TextureButton) -> void:
	if btn == null:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	btn.modulate = Color(1.0, 1.0, 1.0, 0.75)


func _update_debug() -> void:
	if not _debug_lbl.visible:
		return
	var parts: Array[String] = []
	for action: String in _touch_map.values():
		parts.append(action.to_upper().replace("_", " "))
	_debug_lbl.text = " | ".join(parts)


func _on_pause_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
