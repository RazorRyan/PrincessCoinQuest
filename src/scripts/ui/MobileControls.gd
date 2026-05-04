extends CanvasLayer

# Mobile touch controls overlay.
# TouchScreenButton nodes fire Input actions automatically — keyboard input is unaffected.
#
# Positions are recalculated at runtime so buttons stick to screen edges on any
# screen size (essential when stretch/aspect = expand changes the effective viewport width).

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	# ── Left side: d-pad ────────────────────────────────────────────────────────
	# DpadSprite is a Sprite2D whose origin is its centre.
	# BtnLeft / BtnRight are TouchScreenButton with an invisible shape whose
	# hit-box is centred on the node's position.
	# 20 px padding from left and bottom edges.
	var dpad_cx := 58.0
	var dpad_cy := vp.y - 58.0
	$DpadSprite.position = Vector2(dpad_cx, dpad_cy)
	$BtnLeft.position    = Vector2(dpad_cx - 19.0, dpad_cy)
	$BtnRight.position   = Vector2(dpad_cx + 19.0, dpad_cy)

	# ── Right side: action buttons ───────────────────────────────────────────────
	# BtnAttack / BtnJump are TouchScreenButton with a texture_normal.
	# For textured TouchScreenButtons the position is the top-left corner.
	# Buttons are 64×64 px at scale 0.6 → ~38 px rendered.
	# Laid out side-by-side with 8 px gap; 20 px padding from right and bottom.
	var btn_y    := vp.y - 58.0          # top-left y  (bottom pad 20 + height 38)
	$BtnAttack.position = Vector2(vp.x - 104.0, btn_y)   # square (left)
	$BtnJump.position   = Vector2(vp.x - 58.0,  btn_y)   # circle (right)
