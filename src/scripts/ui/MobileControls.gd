extends CanvasLayer

# Mobile touch controls overlay.
# TouchScreenButton nodes fire Input actions automatically — keyboard input is unaffected.
#
# Positions are recalculated at runtime so buttons stick to screen edges on any
# screen size (essential when stretch/aspect = expand changes the effective viewport width).

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Scale all controls 2× for visibility on modern phone displays (e.g. Samsung S25).
	# Do NOT scale the CanvasLayer itself — that shifts children away from screen edges.
	$DpadSprite.scale = Vector2(2.0, 2.0)
	$BtnLeft.scale    = Vector2(2.0, 2.0)
	$BtnRight.scale   = Vector2(2.0, 2.0)
	$BtnAttack.scale  = Vector2(2.0, 2.0)
	$BtnJump.scale    = Vector2(2.0, 2.0)

	# ── Left side: d-pad ────────────────────────────────────────────────────────
	# DpadSprite is a Sprite2D whose origin is its centre.
	# At scale 2× the rendered half-height ≈ 64 px → centre 84 px from bottom
	# (64 px half-height + 20 px padding = 84 px).
	# BtnLeft / BtnRight shapes are 38×77 local units → 76×154 effective at scale 2.
	var dpad_cx := 150.0
	var dpad_cy := vp.y - 84.0
	$DpadSprite.position = Vector2(dpad_cx, dpad_cy)
	$BtnLeft.position    = Vector2(dpad_cx - 38.0, dpad_cy)
	$BtnRight.position   = Vector2(dpad_cx + 38.0, dpad_cy)

	# ── Right side: action buttons ───────────────────────────────────────────────
	# BtnAttack / BtnJump have a 64×64 texture; at scale 2× they render as 128×128.
	# Position is the top-left corner of the scaled button.
	# 20 px padding from right and bottom edges; 10 px gap between buttons.
	var btn_size := 128.0
	var btn_gap  := 10.0
	var pad      := 20.0
	var btn_y    := vp.y - btn_size - pad
	$BtnAttack.position = Vector2(vp.x - btn_size * 2.0 - btn_gap - pad, btn_y)  # square (left)
	$BtnJump.position   = Vector2(vp.x - btn_size - pad,                  btn_y)  # circle (right)

	# ── Top-right: pause button ──────────────────────────────────────────────────
	# Regular Button so it can receive input even while the tree is paused.
	var pause_sz := 72.0
	$BtnPause.size     = Vector2(pause_sz, pause_sz)
	$BtnPause.position = Vector2(vp.x - pause_sz - 20.0, 20.0)
	$BtnPause.add_theme_font_size_override("font_size", 28)
	$BtnPause.process_mode = Node.PROCESS_MODE_ALWAYS
	$BtnPause.pressed.connect(_on_btn_pause_pressed)

func _on_btn_pause_pressed() -> void:
	# Synthesise a ui_cancel action so the HUD's _unhandled_input handler
	# receives it regardless of whether input came from keyboard or touch.
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
