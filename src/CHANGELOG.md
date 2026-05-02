## [2026-05-02] - Lava Hazard system

**Files Changed:**
- `scripts/hazards/LavaHazard.gd` *(new)*
- `scripts/hazards/LavaHazard.gd.uid` *(new)*
- `scenes/hazards/LavaHazard.tscn` *(new)*
- `scenes/levels/forest_levels/Level03.tscn`

**What changed:**

### LavaHazard.gd (`Area2D`)
- `@export var damage := 1` — tunable hit damage
- `@export var cooldown := 0.8` — seconds between damage ticks while player stands in lava
- Tracks player presence with `body_entered` / `body_exited`; applies damage immediately on entry then respects cooldown
- Filters by `is_in_group("player")` — enemies are unaffected
- Plays `"flow"` animation if available, falls back to `"idle"`
- Subtle heat shimmer: pulses sprite alpha between 85 %–100 % via `sin()` in `_process`

### LavaHazard.tscn scene structure
```
LavaHazard (Area2D, collision_layer=4, collision_mask=1)
├── AnimatedSprite2D  (scale 4×1, SpriteFrames "idle" 2-frame gradient animation at 4 fps)
├── CollisionShape2D  (RectangleShape2D 64×14)
└── AudioStreamPlayer2D  (reserved for future SFX)
```
- Frame 0: vertical gradient dark-orange → deep-red  
- Frame 1: vertical gradient bright-yellow-orange → vivid-orange  
- Combined animation gives natural lava flicker without any sprite assets

### Level03 — Lava hazards
- `Hazards` container node added
- `Lava01` at (280, 356) — pit area, well clear of player spawn (119, 313)
- `Lava02` at (448, 356) — second pit near exit approach

**How to test:**
1. Open Level03 in Godot and run the scene
2. Walk the player into a lava tile — hp drops by 1, player gets knockback + invincibility flash
3. Stand on lava — hp drops repeatedly every 0.8 s
4. Confirm enemies are not damaged by lava
5. Confirm lava animation plays and shimmers

---

## [2026-05-02] - Polished moving platform system

**Files Changed:**
- `scripts/platforms/MovingPlatform.gd` *(new)*
- `scenes/platforms/MovingPlatform.tscn` *(new)*
- `scripts/player/Player.gd`
- `scenes/levels/forest_levels/Level02.tscn`

**What changed:**

### MovingPlatform.gd (`AnimatableBody2D`)
- Travels between `StartPoint` and `EndPoint` Marker2D children
- `StartPoint` is at local (0,0) — the platform's scene placement IS the start position
- `EndPoint` default offset (80, 0) — change in editor to set travel direction and distance
- `@export speed := 40.0` — pixels per second, safe and readable for kids
- `@export wait_time := 0.5` — brief pause at each end before reversing
- `@export bob_amount := 1.5` — visual-only Y oscillation; does NOT move the collision shape so `get_floor_velocity()` stays clean and stable
- Both Marker2D world positions are cached in `_ready()` before any movement begins, so the markers (which travel with the body) don't produce drifting targets
- Direction change: `_going_to_end` bool is toggled on arrival; `get_tree().create_timer(wait_time)` drives the pause via `CONNECT_ONE_SHOT`

### MovingPlatform.tscn scene structure
```
MovingPlatform (AnimatableBody2D)
├── Visual (Node2D) ← bob applied here only
│   ├── Shadow (Polygon2D, semi-transparent dark, offset 1,1)
│   ├── Body   (Polygon2D, warm brown, 64×9px)
│   └── TopStrip (Polygon2D, lighter highlight, 64×2px at top)
├── CollisionShape2D (RectangleShape2D 64×10)
├── StartPoint (Marker2D, local 0,0)
└── EndPoint   (Marker2D, local 80,0 — default horizontal travel)
```

### Player.gd — floor velocity inheritance
- Added `if is_on_floor(): velocity.x += get_floor_velocity().x` inside the normal movement block
- Requires `AnimatableBody2D.sync_to_physics = true` (Godot 4 default) so the physics server tracks position deltas and exposes them as floor velocity
- Player walking left/right on platform: combined velocity = player input + platform velocity (correct world-space behaviour)
- During attack/hurt states: `velocity.x` is not modified so platform interaction is seamless

### Level02 — Platform01
- `MovingPlatforms` container node added
- `Platform01` placed at (300, 222) — positioned below Coin05 at (362, 181) so the player can ride the platform rightward and jump up to reach the coin
- Platform travels 80px horizontally (EndPoint default) — safe, slow, clearly readable

**How to test:**
- Run Level02 — brown platform slides left/right with a subtle hover bob
- Walk onto it — player is carried with the platform (no sliding back)
- Jump off mid-travel — player leaves at combined velocity, lands normally
- Ride rightward — reach the elevated coin area that was hard without the platform
- Adjust `EndPoint` position in the Godot editor to change travel distance/direction for any future level

---

## [2026-05-02] - HUD upgrade and pause menu

**Files Changed:**
- `scenes/ui/HUD.tscn`
- `scripts/Hud.gd`

**What changed:**

### HUD restructure (`HUD.tscn`)
- Nodes reorganised into `TopBar` (HBoxContainer, full-width, anchored to top) containing:
  - `HealthBar` (ProgressBar, left — unchanged red/dark style)
  - `CoinLabel` (Label, centre — expands to fill)
  - `LevelLabel` (Label, right-aligned — expands to fill)
- `PauseMenu` (Control, full-screen, hidden by default) added containing:
  - `Overlay` (ColorRect, 60% black, blocks clicks through to game)
  - `Panel` (StyleBoxFlat, centred 208×232px dark panel) with:
    - `TitleLabel` — "PAUSED"
    - `ResumeButton`, `RestartButton`, `MainMenuButton`
- CanvasLayer `process_mode = PROCESS_MODE_ALWAYS` so HUD/pause stays active while tree is paused
- Button signals wired in scene to `_on_resume_pressed`, `_on_restart_pressed`, `_on_main_menu_pressed`
- Pixel font applied to all new labels and buttons

### Hud.gd rewrite
- `@onready` paths updated for new TopBar structure (`$TopBar/HealthBar`, `$TopBar/CoinLabel`, `$TopBar/LevelLabel`)
- `_update_level_label()` — derives display from `GameManager.current_level_index + 1` (shows "Level 1", "Level 2", etc.)
- `_unhandled_input()` — listens for `ui_cancel` (Escape) to toggle pause; works while paused because CanvasLayer is PROCESS_MODE_ALWAYS
- `_toggle_pause()` — sets `get_tree().paused` and toggles `pause_menu.visible`
- `_on_resume_pressed()` — calls `_toggle_pause()` to unpause
- `_on_restart_pressed()` — unpauses then calls `GameManager.restart_level()`
- `_on_main_menu_pressed()` — unpauses then loads `MainMenu.tscn`

**How to test:**
- Run any level — TopBar shows HP bar (left), "Coins: 0 / N" (centre), "Level N" (right)
- Collect a coin — CoinLabel updates immediately
- Take damage — HealthBar shrinks
- Press Escape — pause menu appears over darkened screen; game stops
- Click Resume — game unpauses
- Click Restart Level — level reloads from scratch
- Click Main Menu — returns to main menu

---

## [2026-05-02] - Combat system improvements: knockback, invincibility, attack position passing

**Files Changed:**
- `scripts/player/Player.gd`
- `scripts/enemies/Slime.gd`

**What changed:**

### Attack position fix (`Player.gd`)
- `_on_attack_area_body_entered` now passes `global_position` to `body.take_damage(ATTACK_DAMAGE, global_position)`
- Previously passed no position → enemy `_from_position` was always `Vector2.ZERO` → slime knockback never fired

### Player knockback (`Player.gd`)
- `take_damage()` knockback now separates axes: `velocity.x = knockback_dir.x * KNOCKBACK_FORCE` + explicit `velocity.y = -80.0`
- Previously used `velocity = knockback_dir * KNOCKBACK_FORCE` (full normalized vector) which gave a weak or zero vertical kick when attacker was at same height

### Player invincibility window (`Player.gd`)
- `INVINCIBILITY_DURATION` increased from `0.4` → `0.8s` — prevents repeated hits from chaining
- Hurt flash and invincibility both use this constant so both lengthen automatically (5 flickers at 0.8s vs 2 at 0.4s)

### Enemy knockback vertical kick (`Slime.gd`)
- `take_damage()` now adds `velocity.y = -50.0` on knockback so the slime pops upward slightly when hit
- `_knockback_timer = 0.25` still suppresses normal patrol movement during the knockback

**Knockback direction logic:**
- Slime: `_from_position.direction_to(global_position)` — pushes away from the player's attack source
- Player: `(global_position - from_position).normalized()` then `.x * KNOCKBACK_FORCE` — pushes away horizontally with a fixed upward kick

**How to test:**
- Attack slime → slime pops up and back, plays hurt flash; spamming attack is blocked by cooldown
- Touch slime → player is knocked back with an upward kick; invincibility lasts ~0.8s (5 flickers visible)
- Run into slime twice quickly → second hit blocked by invincibility window

---

## [2026-05-02] - Game feel polish: hit flash, screen shake, sound effects, particle effects

**Files Changed:**
- `scripts/effects/AutoFree.gd` *(new)*
- `scenes/effects/CoinSparkle.tscn` *(new)*
- `scenes/effects/HitBurst.tscn` *(new)*
- `scripts/player/Player.gd`
- `scripts/enemies/Slime.gd`
- `scenes/enemies/Slime.tscn`
- `scripts/pickups/Coin.gd`

**What changed:**

### Particle effects
- `AutoFree.gd` — reusable script that extends `CPUParticles2D`; auto-`queue_free()`s after `lifetime + 0.1s`
- `CoinSparkle.tscn` — 8 yellow particles, one-shot, 0.4s lifetime; spawned at coin position on pickup
- `HitBurst.tscn` — 10 red particles, one-shot, 0.3s lifetime; spawned at slime position on hit

### Screen shake (`Player.gd`)
- Added `shake_camera(amount, duration)` — finds child `Camera2D`, offsets it frame-by-frame with decaying random displacement, resets to zero on finish
- `take_damage()` now calls `shake_camera(4.0, 0.15)` when player is hurt

### Enemy hit feedback (`Slime.gd` + `Slime.tscn`)
- `_play_hurt()` now flashes sprite to `Color(1, 0.4, 0.4)` for 0.15s then reverts to `Color.WHITE`
- New `_spawn_hit_effects()` called from `take_damage()`: plays `hit_sfx`, spawns `HitBurst`, calls `shake_camera(3.0, 0.12)` on the player via group lookup
- `hit_sfx` (`AudioStreamPlayer2D`, `hurt.wav`) node added to `Slime.tscn`

### Coin pickup (`Coin.gd`)
- `_spawn_pickup_effects()` — spawns `CoinSparkle` at coin's position; spawns a detached `AudioStreamPlayer` (uses `PickupSound.stream`) so sound completes after `queue_free()`

**How to test:**
- Run any forest level
- Jump → `jump_sfx` plays (was already wired)
- Collect coin → yellow sparkle burst + coin sound plays cleanly
- Attack slime → slime flashes red + hit sound + red particle burst + subtle camera shake
- Player takes damage → screen shakes + hurt flash + hurt sound

---

## [2026-05-01] - Add intro music to IntroMovie

**Files Changed:**
- `scenes/ui/IntroMovie.tscn`
- `scripts/ui/IntroMovie.gd`

**What changed:**
- `IntroMusic` (`AudioStreamPlayer`) node added to `IntroMovie.tscn`
  - Stream: `CoinFallKingdom_IntroMovie.mp3`
  - `autoplay = false`, `volume_db = -8.0`, `bus = "Music"`
- `IntroMovie.gd` — `intro_music.play(12.0)` called in `_ready()` — `play(offset)` tells Godot to start playback 12 seconds into the track, matching the desired musical entry point
- `_load_first_level()` — uses a parallel Tween to fade the overlay to black **and** fade `volume_db` from -8 → -80 simultaneously over `FADE_DURATION`, then calls `intro_music.stop()` before loading the level — clean audio exit with no pop
- Music stops automatically on skip because `_load_first_level()` is always the exit path (both normal end and skip both call it)

**How `play(12.0)` works:**
`AudioStreamPlayer.play(from_position)` accepts a playback offset in seconds. Passing `12.0` starts the stream at the 12-second mark of the audio file, skipping the intro buildup of the track.

---

## [2026-05-01] - Change default background clear color to black

**Files Changed:**
- `project.godot`

**What changed:**
- `rendering/environment/defaults/default_clear_color` changed from `Color(0.722, 0.871, 0.961, 1)` (default blue) to `Color(0, 0, 0, 1)` (pure black)

**Why:**
Any area not covered by a scene background (empty space beyond camera limits, IntroMovie letterbox bars, level edges) previously showed the engine's default sky blue. Pure black is correct for a dark fantasy platformer and matches the IntroMovie FadeOverlay.

**Camera limits already set (no changes needed):**
All three forest levels have Camera2D limits set (`limit_left=0`, `limit_top=-64`, `limit_right=1280`, `limit_bottom=512`) preventing the camera from showing outside the tile area.

**How to test:**
1. Run any level and walk to the edge — background is black, not blue
2. IntroMovie letterbox bars are seamlessly black
3. MainMenu background image edges blend to black

---

## [2026-05-01] - Fix IntroMovie fade logic and image size

**Files Changed:**
- `scripts/ui/IntroMovie.gd`
- `scenes/ui/IntroMovie.tscn`

**Bugs fixed:**

| # | Bug | Root Cause | Fix |
|---|---|---|---|
| 1 | Image faded in then instantly vanished | Fade direction was inverted — `_fade(1.0, 0.0)` jumped overlay to opaque instantly; `_fade(0.0, duration)` then faded to transparent (wrong direction for fade-out) | Fade-in now calls `_fade(0.0, FADE_DURATION)` (overlay → transparent = reveal); fade-out calls `_fade(1.0, FADE_DURATION)` (overlay → black = hide); skip jump also corrected |
| 2 | Images appeared too large / cropped | `stretch_mode = 6` (KEEP_ASPECT_COVERED) fills the screen and crops edges | Changed to `stretch_mode = 5` (KEEP_ASPECT_CENTERED) — shows full image centred with black letterbox bars |

---

## [2026-05-01] - Intro Movie cinematic sequence

**Files Changed:**
- `scenes/ui/IntroMovie.tscn` *(new)*
- `scripts/ui/IntroMovie.gd` *(new)*
- `scripts/ui/MainMenu.gd`

**Scene Structure:**
```
IntroMovie (Control) — full-screen, script=IntroMovie.gd
├── MovieImage   (TextureRect)  — anchor=full, expand=1, stretch=KEEP_ASPECT_COVERED
├── FadeOverlay  (ColorRect)    — black, starts opaque, mouse_filter=IGNORE
└── SkipLabel    (Label)        — anchored bottom-centre, starts alpha=0
```

**Playback Logic:**
- 7 images loaded from `res://assets/backgrounds/Intro_Movie_N.png`
- Frame durations: frames 1–4 = 2.5 s, frames 5–6 = 3.0 s, frame 7 = waits for input
- Each transition: fade out (0.5 s) → swap texture → fade in (0.5 s)
- Subtle zoom: each frame scales from `1.0 → 1.05` over its display duration (Tween, EASE_OUT)
- Frame 7 fades in the "Press any key to start!" label; waits for any input then calls `GameManager.start_game()`

**Skip Behaviour:**
- Any `InputEventKey`, `InputEventMouseButton` (press only), or `InputEventScreenTouch` sets `_skip_requested = true`
- The `_interruptible_wait()` helper polls this flag each process frame — exits immediately when set
- Skip jumps directly to frame 7 with a clean fade transition; does NOT abort mid-fade
- On frame 7 the same input triggers `_load_first_level()` instead of skipping

**Fade Implementation:**
- `_fade(target_alpha, duration)` creates a one-shot Tween on `FadeOverlay.color:a` and `await`s it
- Start state: FadeOverlay alpha = 1.0 (black screen), ensures clean entry from Main Menu

**MainMenu.gd change:**
- `_on_start_pressed()` now routes to `res://scenes/ui/IntroMovie.tscn` instead of calling `GameManager.start_game()` directly
- `IntroMovie.gd` calls `GameManager.start_game()` at the end, maintaining the same downstream flow

**Test Flow:**
1. Launch → Main Menu
2. Click **Start Game** → black screen → frames 1–7 cycle with fade/zoom
3. Any key mid-sequence → skips to frame 7
4. Frame 7 displays "Press any key to start!" → any key → fades to black → Level 1 loads

---

## [2026-05-01] - Cheat: permanent invincibility toggle in Level Select

**Files Changed:**
- `autoload/GameManager.gd`
- `scripts/ui/LevelSelect.gd`
- `scripts/player/Player.gd`
- `scenes/ui/LevelSelect.tscn`

**What changed:**
- `GameManager.cheat_invincible: bool` added — persists across level loads
- `LevelSelect.tscn` — new `CheckButton` node (`InvincibleToggle`) added above the Back button; label reads "INVINCIBLE MODE"
- `LevelSelect.gd` — reads current flag into toggle on open; `toggled` signal writes back to `GameManager.cheat_invincible`
- `Player.gd` `take_damage()` — guard now: `if _power_up_active or is_invincible or is_dying or GameManager.cheat_invincible: return`

**How to use:**
1. From Main Menu → Options → Level Select screen
2. Toggle **INVINCIBLE MODE** on
3. Choose any level — player cannot take damage for the whole session
4. Toggle off to restore normal gameplay (takes effect immediately in-game)

---

## [2026-05-01] - Music speeds up during invincibility power-up

**Files Changed:**
- `scripts/player/Player.gd`
- `scripts/levels/LevelTemplate.gd`

**What changed:**
- `activate_invincibility()` calls `_set_music_pitch(1.3)` — 30% faster
- Timer expiry calls `_set_music_pitch(1.0)` — restores normal speed
- `_set_music_pitch()` finds the level music player via the `"music_players"` group (fast path), falls back to a full scene-tree scan for any `AudioStreamPlayer` on the Music bus
- `LevelTemplate._start_music()` — music player is now added to the `"music_players"` group so it is found instantly
- `LevelTemplate._on_level_completed()` — resets `pitch_scale = 1.0` before stopping, so pitch does not carry over on level restart

---

## [2026-05-01] - Fix invincibility power-up bugs

**Files Changed:**
- `scripts/powerups/InvinciblePowerUp.gd`
- `scripts/player/Player.gd`
- `scenes/levels/forest_levels/Level03.tscn`

**Bugs fixed:**

| # | Bug | Root Cause | Fix |
|---|---|---|---|
| 1 | Power-up never detected player | Level03 instance had `scale = Vector2(0.05, 0.05)` overriding the scene root, shrinking the CircleShape2D collision radius from 6 px to 0.6 px | Removed the per-instance scale override from Level03.tscn |
| 2 | Character did not turn yellow on pickup | `_process` wrote `sprite.scale = Vector2(pulse, pulse)` (~1.0), overriding the editor-assigned `scale = Vector2(0.05, 0.05)` and corrupting sprite size | Store `_base_scale` in `_ready()`, apply as `sprite.scale = _base_scale * pulse` |
| 3 | Yellow glow wiped immediately by hurt-flash | `_start_hurt_flash()` coroutine unconditionally set `sprite.modulate = Color.WHITE` at the end | Added `if not _power_up_active:` guard before the modulate reset |

---

## [2026-05-01] - Level Select screen + power-up placed in Level 3

**Files Changed:**
- `scenes/ui/LevelSelect.tscn` *(new)*
- `scripts/ui/LevelSelect.gd` *(new)*
- `autoload/GameManager.gd`
- `scripts/ui/MainMenu.gd`
- `scenes/levels/forest_levels/Level03.tscn`

**What changed:**
- `GameManager.load_level_at_index(index)` added — resets coins and loads any level by index without going through the menu
- `LevelSelect.tscn` — full-screen Control with the MainMenu background, dark overlay, PixelOperator8-Bold title, and buttons for Level 1 / 2 / 3 + Back
- `LevelSelect.gd` — connects buttons to `GameManager.load_level_at_index()`; Back returns to MainMenu
- `MainMenu.gd` `_on_options_pressed()` — now opens `res://scenes/ui/LevelSelect.tscn` instead of doing nothing
- `Level03.tscn` — `InvinciblePowerUp` instance added to a `PowerUps` container node at `Vector2(348, 148)`, before the four-slime gauntlet near the exit

---

## [2026-05-01] - Add Invincibility Power-Up system

**Files Changed:**
- `scenes/powerups/InvinciblePowerUp.tscn` *(new)*
- `scripts/powerups/InvinciblePowerUp.gd` *(new)*
- `scripts/player/Player.gd`

**Scene structure:**
```
InvinciblePowerUp (Area2D)
├── AnimatedSprite2D  ← PowerUp_Invincibility.png, pulses via sin() in _process
├── CollisionShape2D  ← CircleShape2D radius=12, scale=0.5
└── PickupSound       ← AudioStreamPlayer2D, power_up.wav on SFX bus
```

**InvinciblePowerUp.gd behaviour:**
- Pulses with a ±8% scale sine wave while idle
- On `body_entered("Player")`:
  - Calls `player.activate_invincibility()`
  - Plays pickup sound, hides sprite, disables collision
  - Waits for sound to finish → `queue_free()`

**Player.gd changes:**

| Addition | Detail |
|---|---|
| `var _power_up_active := false` | Separate flag from hurt iframes |
| `var _power_up_timer := 0.0` | Countdown in `_physics_process` |
| `func activate_invincibility()` | Sets active=true, timer=10.0, modulate=yellow |
| `_physics_process` timer tick | Resets active + `sprite.modulate=WHITE` when expired |
| `take_damage` guard | `if _power_up_active or is_invincible or is_dying: return` |

**Design notes:**
- `_power_up_active` is intentionally separate from `is_invincible` (hurt iframes).
  This prevents hurt-flash logic from running during power-up and avoids timer conflicts.
- Hurt flash uses `sprite.modulate`; during power-up `take_damage` returns early so
  no flash conflict occurs.
- Yellow glow (`Color(1, 1, 0.4)`) resets to `Color.WHITE` when power-up expires.

**How to Test:**
1. Instance `InvinciblePowerUp.tscn` in a level (drag into scene, place near player)
2. Run level — power-up pulses gently
3. Walk over it — pickup sound plays, sprite disappears
4. Player turns yellow — cannot take damage for 10 seconds
5. After 10 seconds — player returns to normal colour, damage works again

---

## [2026-05-01] - Refactor HUD — health bar moved to top-right, removed redundant LevelCompleteLabel

**Files Changed:**
- `scenes/ui/HUD.tscn`
- `scripts/ui/Hud.gd`
- `scripts/Hud.gd` *(duplicate — kept in sync)*

**What changed:**

| Element | Before | After |
|---|---|---|
| `HealthBar` position | Top-left (offset 8,8 → 108,22) | Top-right (anchor=1, offset -118,8 → -8,22) |
| `CoinLabel` position | offset_top=28 (below health bar) | offset_top=8 (top-left, 8px from edge) |
| `LevelCompleteLabel` | Present, shown via signal | **Removed** — LevelCompleteUI handles this |

**HUD node removed:** `LevelCompleteLabel` — was set `visible=true` by `_on_level_completed()`.
This is now fully handled by `LevelCompleteUI.tscn` which is instantiated by `ExitDoor.gd`.
Keeping both caused a duplicate "Level Complete" display.

**Hud.gd cleanup:**
- Removed `@onready var level_complete_label`
- Removed `GameManager.level_completed.connect(_on_level_completed)`
- Removed `func _on_level_completed()`

**How to Test:**
1. Run any level — health bar appears in the **top-right corner**
2. Coin counter appears in the **top-left corner**
3. Take damage — health bar shrinks from the right
4. Complete level — only the `LevelCompleteUI` panel appears (no extra label)

---

## [2026-05-01] - Replace Main Menu buttons with image-based TextureButtons

**Files Changed:**
- `scenes/levels/MainMenu.tscn`
- `scripts/ui/MainMenu.gd`

**What changed:**

Replaced the styled `Button` node with three `TextureButton` nodes using custom artwork:

| Node | Texture |
|---|---|
| `StartGameButton` | `res://assets/backgrounds/StartGame.png` |
| `OptionsButton` | `res://assets/backgrounds/Options.png` |
| `ExitButton` | `res://assets/backgrounds/Exit.png` |

Removed all `StyleBoxFlat` sub-resources and font ext-resources — no longer needed.

**Scene structure:**
```
MainMenu (Control)
├── Background (TextureRect)     ← PrincessCoinQuestMainMenu.png, Keep Aspect Covered
└── ButtonContainer (VBoxContainer)
    ├── StartGameButton (TextureButton)  ← StartGame.png
    ├── OptionsButton   (TextureButton)  ← Options.png
    └── ExitButton      (TextureButton)  ← Exit.png
```

**Layout:** `ButtonContainer` anchored `left=0 top=0.55 right=1 bottom=1` — buttons appear
in the lower 45% of the screen, horizontally centered by VBoxContainer alignment.
Vertical separation = 24px.

**Signal connections (MainMenu.gd):**
- `StartGameButton.pressed` → `GameManager.start_game()` → loads Level01
- `OptionsButton.pressed` → `pass` (placeholder)
- `ExitButton.pressed` → `get_tree().quit()`

**How to Test:**
1. Press **F5** — main menu opens with background image
2. Three image buttons are visible in the lower half of the screen
3. Click/tap **START GAME** → Level01 loads
4. Click/tap **OPTIONS** → nothing happens (placeholder)
5. Click/tap **EXIT** → game closes

---

## [2026-05-01] - Add Main Menu scene

**Files Changed:**
- `scenes/levels/MainMenu.tscn` *(fully replaced — was a misrouted gameplay scene)*
- `scripts/ui/MainMenu.gd` *(new)*
- `autoload/GameManager.gd` *(added `start_game()`)*
- `project.godot` *(updated `run/main_scene` to point to MainMenu)*

**Scene structure:**

```
MainMenu (Control) — fills viewport, root of scene
├── Background (ColorRect) — sky blue #B8DEF5, fills viewport
├── CenterContainer — fills viewport, auto-centers child
│   └── VBoxContainer — separation = 16
│       ├── TitleLabel — "Princess Coin Quest", PixelOperator Bold 28px, gold
│       ├── SubtitleLabel — "Collect all coins. Reach the door.", PixelOperator 12px
│       ├── Spacer — 20px vertical gap
│       ├── StartButton — "START GAME", styled purple/gold (matches LevelCompleteUI)
│       └── FooterLabel — control hints, PixelOperator 10px
```

**Behavior:**
- `StartButton` pressed → `GameManager.start_game()`
- `start_game()` resets `coins_collected`, `total_coins`, `current_level_index = 0`,
  then loads `levels[0]` (`res://scenes/levels/Level01.tscn`)

**GameManager.start_game():**
Resets all coin state and level index before transitioning to Level01.
Ensures a clean game state whether arriving from the title screen or a replay.

**project.godot:**
`run/main_scene` changed from the previous scene UID (`uid://opwh0leivwii`) to
`uid://cy25jbugetljk` (MainMenu.tscn). The game now opens on the main menu at startup.

**Fonts:**
- Title: `PixelOperator8-Bold.ttf` (`res://assets/fonts/PixelOperator8-Bold.ttf`)
- Subtitle / footer: `PixelOperator8.ttf` (`res://assets/fonts/PixelOperator8.ttf`)
- Both are already in the project and imported.

**How to Test:**
1. Press **F5** (Run Project) in Godot — main menu appears immediately
2. Title "Princess Coin Quest" is visible in gold pixel font
3. Subtitle and footer are readable in smaller pixel font
4. Hover over **START GAME** — button lights up purple/bright
5. Press **START GAME** — Level01 loads, coins reset to 0
6. Complete Level01 → Level02 → press **REPLAY** on Level02 — still works correctly

---

## [2026-05-01] - Implement repeatable level transitions (Level01 → Level02)

**Files Changed:**
- `autoload/GameManager.gd`
- `scripts/levels/ExitDoor.gd`
- `scripts/ui/LevelCompleteUI.gd`

**What changed:**

### GameManager.gd
- Removed `current_level: int = 1` (format-string approach)
- Added `levels: Array[String]` — explicit list of level scene paths:
  - `res://scenes/levels/Level01.tscn`
  - `res://scenes/levels/Level02.tscn`
- Added `current_level_index: int = 0` — tracks position in the levels array
- Added `complete_level()` — emits `level_completed` signal (music stop handled by LevelTemplate via signal)
- Added `has_next_level() -> bool` — returns true if a next entry exists in the levels array
- Updated `restart_level()` — uses `levels[current_level_index]` instead of format string
- Updated `go_to_next_level()` — increments `current_level_index` and loads from the levels array; prints "No more levels. Game complete." if at end

### ExitDoor.gd
- Replaced direct `GameManager.level_completed.emit()` with `GameManager.complete_level()`
- No hardcoded level paths; level progression is fully owned by GameManager

### LevelCompleteUI.gd
- **Replay button** now calls `GameManager.restart_level()` (was `get_tree().reload_current_scene()`)
  - Correctly resets `coins_collected` in GameManager before reloading
- **Next Level button** now calls `GameManager.go_to_next_level()`
- On `_ready()`: if `GameManager.has_next_level()` returns false, Next Level button text is changed to `"GAME COMPLETE"` and the button is disabled

**How to Test:**
1. Run `Level01.tscn`
2. Collect all coins → door opens
3. Enter door → success sound plays, Level Complete UI appears after 0.4 s
4. Press **REPLAY** → Level01 reloads with coins reset
5. Complete Level01 again → press **NEXT LEVEL** → Level02 loads
6. Complete Level02 → Level Complete UI shows **GAME COMPLETE** (button disabled)
7. Press **REPLAY** on Level02 → Level02 reloads correctly

---

## [2026-04-27] - Fix gray background — clear color + ParallaxLayer setup

**Files Changed:**
- project.godot *(safe text edit — not affected by scene editor)*
- scenes/levels/Level01.tscn *(Godot editor steps required — see below)*

**Root Cause (3 compounding issues):**

1. **No clear color set** — Godot defaults to gray `#808080` anywhere no sprite covers the screen.
2. **Sprite2D in ParallaxLayer has no texture** — blank, draws nothing.
3. **No motion_mirroring on ParallaxLayer** — even if a texture were set, a single non-tiling sprite cannot cover the full 1280px level width as the camera scrolls.

**Fix applied in project.godot:**
Added `environment/defaults/default_clear_color = Color(0.722, 0.871, 0.961, 1)` (sky blue `#B8DEF5`).
This is a global safety net — any pixel with no sprite covering it renders as sky blue instead of gray.

**Fix required in Godot editor (Level01.tscn):**

### Step 1 — ParallaxLayer node
1. Select `ParallaxBackground → ParallaxLayer` in the Scene panel
2. In the Inspector set:
   - **Motion Scale**: `Vector2(0.2, 0)` — background scrolls at 20% camera speed (parallax effect)
   - **Motion Mirroring**: `Vector2(256, 0)` — tiles the background every 256px horizontally (infinite coverage)

### Step 2 — Sprite2D node
1. Select `ParallaxBackground → ParallaxLayer → Sprite2D`
2. In the Inspector set:
   - **Texture**: `res://assets/tilesets/spritesheet-backgrounds-default.png`
   - **Region → Enabled**: ✅ ON
   - **Region → Rect**: `Rect2(0, 0, 256, 256)` — uses the top-left sky panel only
   - **Texture Filter**: `Nearest` (crisp pixel art)
   - **Position**: `Vector2(0, -32)` — shifts sky up slightly so it sits in the upper level area
3. Press **Ctrl+S**

**Why this works:**
- `motion_mirroring = Vector2(256, 0)` makes Godot automatically tile the 256px sky sprite across the full level width without needing extra nodes.
- `motion_scale = Vector2(0.2, 0)` creates the parallax effect (sky moves slower than world).
- The `Background` TileMapLayer already draws ground decoration tiles on top.
- The `default_clear_color` covers any remaining gap at the very edges.

**Background spritesheet reference:**
The spritesheet `spritesheet-backgrounds-default.png` (1027×1027) has 4 panels at ~256×256px each:

| Column 0 | Column 1 | Column 2 | Column 3 |
|---|---|---|---|
| Sky only (use this) | Desert/sand hills | Green grass hills | Autumn/mushroom hills |

**Camera2D limits (unchanged, correct for this level):**

| Limit | Value |
|---|---|
| limit_left | 0 |
| limit_right | 1280 |
| limit_top | -64 |
| limit_bottom | 512 |

**Z-index order (background → foreground):**

| Node | z_index |
|---|---|
| ParallaxBackground | -10 (already set) |
| Background (TileMapLayer) | 0 |
| Mid (TileMapLayer) | 0 |
| ExitDoor | 4 |
| Player | 5 |
| Slime | 5 |
| Coin | 6 |

**How to Test:**
1. Run `Level01.tscn` — the background should be sky blue, never gray
2. Walk/run the player all the way to the right edge (x~1280) — no gray
3. Walk all the way to the left edge (x=0) — no gray
4. Jump to the top of the level — background is sky blue, not gray
5. Sky background should appear to scroll slightly slower than the tiles (parallax)

---

## [2026-04-27] - Fix Z-index rendering order (objects hidden behind tiles)

**Files Changed:**
- scenes/levels/Level01.tscn
- scenes/pickups/Coin.tscn
- scenes/enemies/Slime.tscn

**Root Cause:**
The scene hierarchy was already correct — all gameplay nodes (Player, Coins, Enemies,
ExitDoor) were direct children of the root Node2D, NOT inside ParallaxBackground.

The actual bug was `Mid (TileMapLayer)` having `z_index = 1` set in the Godot editor.
This caused the ground tiles to render ON TOP of all gameplay objects (Player, Coins,
Slime, ExitDoor) which had z_index = 0. Objects appeared "behind" the tileset.

Additionally, no explicit z_index was set on any gameplay objects, so rendering order
relied entirely on tree position.

**Changes:**

| File | Node | Change | Reason |
|---|---|---|---|
| `Level01.tscn` | `Mid (TileMapLayer)` | Removed `z_index = 1` | Tiles must render BEHIND gameplay objects |
| `Level01.tscn` | `ParallaxBackground` | `z_index = -10` | Explicitly behind all other nodes |
| `Level01.tscn` | `Player` | `z_index = 5` | Renders in front of tiles, enemies, coins |
| `Level01.tscn` | `ExitDoor` | `z_index = 4` | Renders above tiles |
| `Level01.tscn` | `Player` position | `127.00002` → `127` | Clean up editor float noise |
| `Coin.tscn` | `Coin (root)` | `z_index = 6` | Coins render above all, visible when near tiles |
| `Slime.tscn` | `Slime (root)` | `z_index = 5` | Same level as player, above tiles |

**Z-Index table (final, all levels):**

| Node | z_index | Note |
|---|---|---|
| ParallaxBackground | -10 | Always behind |
| TileMap (Node2D wrapper) | 0 (default) | Ground layer |
| Background (TileMapLayer) | 0 (default) | Decorative tiles |
| Mid (TileMapLayer) | 0 (default) | Collision tiles — MUST be 0, not 1 |
| ExitDoor | 4 | Above tiles |
| Player | 5 | Above tiles and enemies |
| Slime | 5 (set in Slime.tscn) | Same level as player |
| Coin | 6 (set in Coin.tscn) | Topmost gameplay object |
| HUD (CanvasLayer) | — | CanvasLayer, always on top regardless |

**How to Test:**
1. Run `Level01.tscn` — player must be visible on screen, not hidden by tiles
2. Slime must be visible patrolling on platforms
3. All coins must be visible and floating above the ground/platform tiles
4. ExitDoor must be visible
5. Background sprite must be behind all tiles and objects

---

## [2026-04-27] - Fix tile offset (Mid TileMapLayer position drift)

**Files Changed:**
- scenes/levels/Level01.tscn *(must be fixed inside Godot editor — see below)*

**Root Cause:**
After the TileMap → TileMapLayer migration, the `Mid` TileMapLayer node (child of the
`TileMap` Node2D wrapper) accumulated an incorrect position offset. The offset grew
across editor sessions: `(40, 0)` → `(40, 56)` → `(40, 103)` because the file was
being text-edited while Godot had it open, causing each editor save to re-apply a
growing drag delta.

The parent `TileMap` Node2D already provides the correct world offset `(0, 2)`.
`Mid` must have `position = (0, 0)`. The non-zero offset shifts every tile's visual
rendering AND its physics collision body, causing the player and enemies to be
misaligned with the ground.

**Fix (Godot editor only):**
1. Open `Level01.tscn`
2. Scene panel → expand `TileMap` → select `Mid`
3. Inspector → Node2D > Transform > Position → set **X = 0, Y = 0**
4. Ctrl+S

**Z-ordering analysis:**
The scene tree order already provides correct draw order. No explicit `z_index`
values are required:

| Tree position | Node | Draw order |
|---|---|---|
| 1st | ParallaxBackground | Behind everything ✓ |
| 2nd | TileMap (Node2D) | Ground layer ✓ |
| 3rd | Coins | Above tiles ✓ |
| 4th | Enemies | Above tiles ✓ |
| 5th | ExitDoor | Above enemies ✓ |
| 6th | Hud (CanvasLayer) | Always on top (CanvasLayer) ✓ |
| 7th | Player | Topmost Node2D object ✓ |

No gameplay nodes are inside ParallaxLayer. Scene hierarchy is correct.

**How to Test:**
1. Run `Level01.tscn` — player must spawn standing on solid ground
2. Walk the full level — all tiles visible, no gaps, no floating platforms
3. All platforms are solid (no fall-through)
4. Background is behind all gameplay objects

---

**Z-Index reference table (for all future levels):**

| Node | z_index | Note |
|---|---|---|
| ParallaxBackground | -10 | Always behind |
| TileMap / TileMapLayer | 0 (default) | Ground layer |
| Coins container children | 0 (default) | Above tiles via tree order |
| Enemies container children | 0 (default) | Above tiles via tree order |
| ExitDoor | 1 | Explicit, above tiles |
| Player | 2 | Always in front |
| HUD (CanvasLayer) | — | CanvasLayer ignores z_index, always on top |

**How to Test:**
1. Run `Level01.tscn` — ground tiles must appear at the correct position (player spawns on solid ground, not floating or falling through).
2. Walk the full level — no tile gaps, no hover tiles.
3. Player must appear in front of Slime when overlapping.
4. Background sprite must be fully behind all tiles and objects.
5. HUD must be on top at all times.

---

## [2026-04-27] - Fix player scale, jump height, and camera zoom

**Files Changed:**
- scenes/player/Player.tscn
- scripts/player/Player.gd
- scenes/levels/Level01.tscn

**Root Cause:**
`CharacterBody2D` root had `scale = Vector2(2, 2)`. This doubled the collision shape in world space (14×31 → 28×62px = 3.9 tiles tall). Jump velocity of -320 only reached ~52px max height but row-9 platforms sat 64px above the ground — unreachable. The camera had no zoom, making 16px tiles look tiny.

**Changes:**

| File | Change | Reason |
|---|---|---|
| `Player.tscn` | Removed `scale = Vector2(2, 2)` from root | Body collision is now native 14×31px ≈ 2 tiles tall ✓ |
| `Player.gd` | `JUMP_VELOCITY` -320 → -400 | Max jump height 52px → 82px — can comfortably reach all platforms |
| `Player.gd` | `SPEED` 130 → 160 | Feels responsive at native scale |
| `Level01.tscn` | `Camera2D zoom = Vector2(2, 2)` | 16px tiles render 32px on screen — same visual result, correct physics |
| `Level01.tscn` | Camera limits set (0–1280 / -64–512) | Prevents camera leaving level bounds |
| `Level01.tscn` | Coin02 y: 94→120, Coin03 y: 110→120 | Were floating 30px above Platform A surface |
| `Level01.tscn` | Player start: (27,181) → (48,188) | Clean column-3 spawn, feet near ground surface |

**Level Design Spacing Rules (for future levels):**
- Tile size: 16px world units
- Standard jump (ground to platform): max 4–5 tile gap (64–80px) with JUMP_VELOCITY -400
- Platform width: min 4 tiles so slimes can patrol and player can land
- Horizontal gap between platforms: max 4 tiles (64px) for comfortable leaps
- Min vertical clearance under ceilings: 3 tiles (48px) — player body is ~2 tiles tall
- Camera zoom=2 is always set on Camera2D in every level

**How to Test:**
1. Run `Level01.tscn` — player should look correctly sized (~2 tiles tall in the zoomed view)
2. Jump from ground to any platform — all platforms are reachable
3. Movement feels responsive, not floaty

---

## [2026-04-27] - Level01 full redesign — "Princess's First Adventure"

**Files Changed:**
- scenes/levels/Level01.tscn

**Level Layout:**
All tiles are 16×16px. Ground surface at pixel y=208 (tile row 13).

| Area | Tile row | Tile X range | Surface Y |
|---|---|---|---|
| Ground floor | 13 | 0–77 | 208 |
| Platform A | 10 | 6–10 | 160 |
| Platform B | 9 | 14–19 | 144 |
| Platform C (highest) | 8 | 25–30 | 128 |
| Platform D | 10 | 35–40 | 160 |
| Platform E | 9 | 46–52 | 144 |
| Platform F (exit) | 10 | 58–65 | 160 |

**Objects Placed:**
- 12 coins — spread across ground path and all platforms to guide the player left→right
- 3 slimes — Slime01 on Platform B (272,132), Slime02 on Platform D (592,148), Slime03 on Platform E (784,132)
- ExitDoor — on Platform F at (1016,128), scale (2,2), door bottom aligned to platform surface
- Player — spawn at (40,187) on ground, near left edge

**Camera:**
- Camera2D moved from scene root to child of Player node — now follows the player automatically
- `position_smoothing_enabled = true`, speed 8.0

**How to Test:**
1. Open and run `Level01.tscn`
2. Player spawns on the left ground — run right
3. Jump up to platforms — coins are on each platform and ground path
4. Defeat or dodge the 3 slimes
5. Collect all 12 coins — exit door opens
6. Reach Platform F and walk into the exit door — Level Complete dialog appears

---

## [2026-04-27] - Level Complete dialog system

**Files Changed:**
- scripts/ui/LevelCompleteUI.gd (new)
- scripts/ui/LevelCompleteUI.gd.uid (new)
- scenes/ui/LevelCompleteUI.tscn (new)
- scripts/levels/LevelTemplate.gd
- scripts/levels/ExitDoor.gd

**What Changed:**
- Created `LevelCompleteUI.tscn` — a `CanvasLayer` (layer 10) with a centered Panel containing a VBoxContainer with a "Level Complete!" Label, a "Replay" Button, and a "Next Level" Button (placeholder).
- `LevelCompleteUI.gd` — Replay calls `get_tree().reload_current_scene()`; Next Level is a no-op placeholder.
- `ExitDoor.gd` — after the 0.4s SFX delay, instantiates `LevelCompleteUI` and adds it to the current scene. Removed the direct `GameManager.go_to_next_level()` call.
- `LevelTemplate.gd` — connects to `GameManager.level_completed` signal in `_ready()`. On trigger, stops the music player if it is playing.

**How to Test:**
1. Run `Level01.tscn`.
2. Collect all coins (exit door opens).
3. Walk into the exit door — success SFX plays, music stops, "Level Complete!" dialog appears.
4. Click **Replay** — level restarts from the beginning.
5. Click **Next Level** — nothing happens (placeholder).

---



**Files Changed:**
- scenes/levels/Level01.tscn
- project.godot

**What Changed:**
- Updated `Level01.tscn` ext_resource path from `CoinCrownCaravan.mp3` to `CoinCrownCaravan_SAI.mp3` to match the renamed file.
- Set `buses/default_bus_layout` in `project.godot` to `res://in_game_default_audio_setup.tres`. Previously empty, so the SFX and Music buses never existed at runtime and volume settings had no effect.

**How to Test:**
- Run `Level01.tscn` — music plays and respects the Music bus volume. SFX respect the SFX bus volume.

---

## [2026-04-27] - Route all SFX to SFX bus, music to Music bus

**Files Changed:**
- scenes/player/Player.tscn
- scenes/enemies/Slime.tscn
- scenes/levels/ExitDoor.tscn
- scenes/pickups/Coin.tscn
- scripts/levels/LevelTemplate.gd

**What Changed:**
- Added `bus = &"SFX"` to all SFX `AudioStreamPlayer` / `AudioStreamPlayer2D` nodes (jump, hurt, attack, lose, splat, success, coin pickup).
- Dynamically created music `AudioStreamPlayer` in `LevelTemplate.gd` now sets `bus = &"Music"`.

---

## [2026-04-27] - Level 1 music: CoinCrownCaravan_SAI (first 60s on repeat)

**Files Changed:**
- scripts/levels/LevelTemplate.gd
- scenes/levels/Level01.tscn

**What Changed:**
- Added optional music support to `LevelTemplate.gd` via `@export var level_music: AudioStream` and `@export var music_loop_end: float = 60.0`.
- On `_ready()`, if `level_music` is set, an `AudioStreamPlayer` is created dynamically and a `Timer` fires every `music_loop_end` seconds to restart playback from the beginning — achieving a clean loop of the first 60 seconds only.
- `Level01.tscn` now sets `level_music = CoinCrownCaravan_SAI.mp3` and `music_loop_end = 60.0`.

**How to Test:**
- Open and run `Level01.tscn` in Godot. Music should start immediately and loop back to the beginning after 60 seconds.

---

## [2026-04-27] - Fix SFX parser error and UID mismatches

**Files Changed:**
- scenes/player/Player.tscn
- scenes/enemies/Slime.tscn
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Root Cause:**
Three compounding issues prevented all SFX from playing:
1. `preload()` consts in scripts caused a **Parser Error** at compile time (`lose.wav` UID not in Godot's import cache), preventing the entire script from loading — so no `.play()` call could ever execute.
2. `lose.wav` UID in `Player.tscn` was wrong (`uid://bm8qf6vpymhib` vs actual `uid://deguctkj8x2r4`).
3. `splat_double_quick.wav` UID in `Slime.tscn` was wrong (`uid://c7amf51hobfcp` vs actual `uid://bmopn73lu6eaq`).

**Fix:**
- Removed all `const _SFX_*` preloads from `Player.gd` and `Slime.gd`. They were redundant — the streams are already assigned via `stream = ExtResource(...)` in the `.tscn` files, and `preload()` triggers a parse-time filesystem check that fails if Godot's import cache is stale.
- Removed corresponding `_ready()` stream assignment lines from both scripts.
- Fixed `lose.wav` UID in `Player.tscn` to match the actual `.import` file.
- Fixed `splat_double_quick.wav` UID in `Slime.tscn` to match the actual `.import` file.

**Lesson:**
`preload()` at the `const` level is evaluated at parse time. If the imported binary cache is missing or the UID doesn't match, it crashes the entire script — silently breaking all features in that file. Always use `.tscn` stream assignments or `load()` at runtime for audio resources added externally.

---

## [2026-04-27] - Implement full SFX system for player and slime

**Files Changed:**
- scenes/player/Player.tscn
- scripts/player/Player.gd
- scenes/enemies/Slime.tscn
- scripts/enemies/Slime.gd

**Summary:**
- `Player.tscn`: Replaced `AudioStreamPlayer2D` nodes with `AudioStreamPlayer` (non-positional) for `jump_sfx`, `hurt_sfx`. Added `attack_sfx` and `lose_sfx` nodes. Added `ext_resource` entries for all four WAV files with their correct UIDs.
- `Player.gd`: Added `const _SFX_*` preloads for all four audio files. Added `@onready` vars for all four nodes. In `_ready()`, assigns each stream via code (bypasses Godot .tscn caching). Added `.play()` calls: `_jump_sfx` on jump, `_attack_sfx` on attack, `_hurt_sfx` on `take_damage`, `_lose_sfx` on `die()`.
- `Slime.tscn`: Added `ext_resource` for `splat_double_quick.wav`. Added `splat_sfx` `AudioStreamPlayer2D` node with stream assigned.
- `Slime.gd`: Added `const _SFX_SPLAT` preload. Added `@onready var _splat_sfx`. Assigns stream in `_ready()`. Added `_splat_timer` that fires `_splat_sfx.play()` every 3–6 seconds while the slime is alive.

**Root Cause:**
- Player SFX nodes existed in the scene but had no streams assigned.
- `attack_sfx` and `lose_sfx` nodes were entirely missing from the scene.
- Slime had no audio nodes at all.
- All `.play()` call sites had been removed from both scripts.
- Using `AudioStreamPlayer` (non-positional) for player sounds avoids 2D audio listener distance attenuation issues.
- Streams are assigned in `_ready()` via `preload` to guarantee they load regardless of `.tscn` editor cache state.

---

## [2026-04-27] - Level complete message on door entry

**Files Changed:**
- autoload/GameManager.gd
- scripts/levels/ExitDoor.gd
- scenes/ui/HUD.tscn
- scripts/Hud.gd

**Summary:**
- `GameManager.gd`: added `signal level_completed`.
- `ExitDoor.gd`: emits `GameManager.level_completed` immediately when the player enters the unlocked door, before the 0.4 s success-sound wait.
- `HUD.tscn`: added `LevelCompleteLabel` — a `Label` anchored to the vertical centre of the screen, full-width, using `PixelOperator8-Bold` at 24 px, hidden by default.
- `Hud.gd`: connects to `GameManager.level_completed` in `_ready()`; `_on_level_completed()` sets `LevelCompleteLabel.visible = true`.

**Reason:**
No feedback was shown to the player when exiting a level. The message displays during the brief sound delay before the next scene loads.

---

## [2026-04-27] - ExitDoor animations and success sound

**Files Changed:**
- scenes/levels/ExitDoor.tscn
- scripts/levels/ExitDoor.gd

**Summary:**
- `ExitDoor.tscn`: replaced `Sprite2D` with `AnimatedSprite2D` backed by a `SpriteFrames` resource with two single-frame animations (`closed` → `door_closed.png`, `open` → `door_open.png`). Added `AudioStreamPlayer2D` node named `success_sfx` preloaded with `Retro Success Melody 04 - electric piano 2.wav`.
- `ExitDoor.gd`: plays `"closed"` on `_ready()`; plays `"open"` and the success sound on unlock/entry; removed debug `print`; guards against double-play with `success_sfx.playing` check; waits 0.4 s before calling `GameManager.go_to_next_level()`.

**Reason:**
Door had no visual state difference between locked and unlocked, and no audio feedback when the player successfully exited a level.

---

## [2026-04-27] - Player hurt flash effect

**Files Changed:**
- scripts/player/Player.gd

**Summary:**
- Added `_start_hurt_flash()`: loops for the duration of `INVINCIBILITY_DURATION`, alternating sprite modulate between red (`Color(1, 0.25, 0.25)`) and semi-transparent white (`Color(1, 1, 1, 0.4)`) every 0.07 s. Resets to `Color.WHITE` after the last flash.
- `take_damage()` calls `_start_hurt_flash()` immediately after `sprite.play("hurt")`.

**Reason:**
No visual indication that the player had taken damage beyond the hurt animation. The red flicker communicates the hit and makes the invincibility window visible.

---

## [2026-04-27] - Fix enemy health bar not depleting to zero on kill

**Files Changed:**
- scripts/enemies/Slime.gd

**Summary:**
- `take_damage()`: moved `_update_health_bar()` call to run unconditionally before the `hp <= 0` branch. Previously it was only called in the `else` branch, so the bar was never updated when the killing blow was dealt.

**Reason:**
The enemy health bar showed the pre-death value instead of 0 when the slime was killed.

---

## [2026-04-27] - Fix HUD health bar not connecting to player

**Files Changed:**
- scripts/player/Player.gd
- scripts/Hud.gd

**Summary:**
- `Player.gd`: added `add_to_group("player")` in `_ready()`. Code-based group registration is reliable regardless of scene load order; the `.tscn` `groups` property can fail for sub-scenes.
- `Hud.gd`: rewrote `_connect_player()` to use `get_nodes_in_group("player")` and check `.is_empty()`. If the group is empty, `await get_tree().process_frame` suspends and retries next frame. Guards against double-connecting with `is_connected`.

**Reason:**
`get_first_node_in_group("player")` returned `null` when HUD's deferred call ran before Player had registered itself, causing the health bar to never receive the initial value or subsequent `hp_changed` signals.

---

## [2026-04-27] - Fix HUD HealthBar overlapping CoinLabel

**Files Changed:**
- scenes/ui/HUD.tscn

**Summary:**
- `CoinLabel`: changed `offset_top` from `0` to `28` so it sits below the health bar row.
- `HealthBar`: unchanged position (offset 8–108 x, 8–22 y).

**Reason:**
Both nodes defaulted to the top-left corner, causing visual overlap.

---

## [2026-04-27] - Player and enemy health bars

**Files Changed:**
- scenes/ui/EnemyHealthBar.tscn (new)
- scenes/ui/HUD.tscn
- scenes/player/Player.tscn
- scripts/Hud.gd
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Created `EnemyHealthBar.tscn`: a small `ProgressBar` (32×4 px, red fill, dark background) positioned 28 local px above origin. Hidden by default, shown on first hit.
- `Player.gd`: added `signal hp_changed(current, maximum)`. Emitted in `_ready()` and in `take_damage()` after hp is decremented.
- `Player.tscn`: added `player` group so HUD can locate the Player via `get_first_node_in_group`.
- `Hud.gd`: added `@onready var health_bar: ProgressBar = $HealthBar`. In `_connect_player()` (called deferred from `_ready()`), finds the Player node, connects `hp_changed`, and sets the initial bar value.
- `HUD.tscn`: added `HealthBar` ProgressBar node (100×12 px, top-left anchor, same red style).
- `Slime.gd`: preloads `EnemyHealthBar.tscn`. In `_ready()`, instantiates and adds it as a child. After each `take_damage()` call that doesn't kill, calls `_update_health_bar()` which sets `value = hp / max_hp` and makes the bar visible.

**Reason:**
No visual health feedback existed. Player had no way to know their remaining HP and enemies gave no indication of damage taken.

---

## [2026-04-27] - Fix player self-damage on attack; fix Slime Hitbox targeting

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- `_on_attack_area_body_entered`: added `if body == self: return` as the first guard. Prevents the player from damaging themselves if AttackArea's collision mask includes the Player's own layer.
- `_on_hitbox_body_entered`: changed `if body.has_method("take_damage")` to `if body.name == "Player" and body.has_method("take_damage")`. Prevents Slimes from accidentally damaging other Slimes or any other body that happens to have `take_damage`.

**Reason:**
When `AttackArea.monitoring` is enabled, Godot fires `body_entered` for every body currently overlapping the area — including the Player's own CharacterBody2D if the AttackArea mask includes the Player's physics layer. The `has_method("take_damage")` check passed because Player has that method, causing the player to deal damage to themselves on every attack. The `body == self` guard is unconditional and requires no collision layer changes. The Slime Hitbox issue was a separate over-broad `has_method` check that could hit any body with `take_damage`, including other Slimes.

---

## [2026-04-26] - Fix player floating above platforms

**Files Changed:**
- scripts/player/Player.gd

**Summary:**
- Added `floor_snap_length = 8.0` in `_ready()`. This prevents the 1–2 frame physics de-sync when the player walks over tile seams, where the character briefly loses floor contact and visually hops.

**Scene adjustments required (in Godot editor):**
- `CollisionShape2D` position.x: change from `-7` to `0` — removes an asymmetric left-shift that was causing uneven wall collision and visual misalignment.
- `AnimatedSprite2D` offset.y: set to approximately `8` (tune visually) — compensates for transparent padding rows at the bottom of the warrior sprite sheet frames, aligning the visible feet with the physics floor contact point.

**Reason:**
The warrior sprite sheet has transparent padding at the bottom of each 44px frame. With no sprite offset set, the visible character feet were drawn above the collision shape's bottom edge, making the player appear to float. The x=-7 collision offset was a secondary misalignment. `floor_snap_length = 1.0` (Godot default) was too small to absorb tile-seam transitions, causing visible micro-hops during movement.

---

## [2026-04-26] - Fix Slime raycast positions for 3x parent scale

**Files Changed:**
- scripts/enemies/Slime.gd

**Summary:**
- Changed `wall_check.position.x` from `18 * direction` to `6 * direction` (local units).
- Changed `wall_check.target_position` from `Vector2(18 * direction, 0)` to `Vector2(8 * direction, 0)`.
- Changed `floor_check.position.x` from `12 * direction` to `7 * direction`.
- Added temporary debug `print` to verify `is_colliding()` results at runtime.

**Reason:**
The Slime root node has `scale = Vector2(3, 3)`. RayCast2D positions are in local space, which Godot multiplies by 3 for world space. The old values (18 local = 54 world) placed the ray origin 36 px past the body edge (17.5 px world half-width), so the ray started embedded behind or inside wall tiles. A ray that starts past a surface never "enters" it, so `is_colliding()` always returned false and the slime never flipped. The new values (6 local = 18 world) align the ray origin with the body edge and extend it 8 local (24 world) px ahead, correctly detecting tiles in the slime's path.

---

## [2026-04-26] - Slime hurt and die animations

**Files Changed:**
- scripts/enemies/Slime.gd

**Summary:**
- Replaced modulate tween with `_play_hurt()`: sets `_is_hurt = true`, plays "hurt" animation for 0.3s, then clears the flag and resumes "walk".
- `die()` now sets `_is_dying = true`, zeroes velocity, plays "die", waits 0.6s (timer used because the animation loops), then `queue_free()`.
- Added `_is_hurt` and `_is_dying` state guards. `sprite.play("walk")` is blocked while either is true. `_physics_process` returns early while `_is_dying`. `take_damage` is a no-op while `_is_dying`.

**Reason:**
`sprite.play("walk")` was called unconditionally every physics frame, immediately overriding any hurt or die animation on the same frame it was triggered. State flags prevent the walk call from stomping the new animations.

---

## [2026-04-26] - Fix slime dying in one hit and stuck-on-wall stutter

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Player: Added `_attack_hits` dictionary, cleared at the start of each swing. `_on_attack_area_body_entered` checks if the body is already in the set before dealing damage, preventing the same body being hit multiple times in one attack window.
- Slime: Added `force_raycast_update()` calls after updating `wall_check` and `floor_check` positions, ensuring `is_colliding()` reflects the current-frame position rather than the previous frame's stale result.
- Slime: Added `_knockback_timer`. When hit, `velocity.x` is set to the knockback impulse and `_knockback_timer = 0.25`. Patrol velocity (`velocity.x = speed * direction`) is only written when the timer has expired, preventing the knockback from being overwritten immediately.
- Slime: Increased `_flip_cooldown` reset to `0.5s`.

**Reason:**
- `body_entered` fires each time a body enters the area. If a slime left and re-entered the attack area within the 0.25s monitoring window (e.g. due to knockback), it received a second hit and could die from a single player attack.
- Godot's RayCast2D auto-updates before `_physics_process`, so repositioning a ray mid-frame and reading `is_colliding()` returned stale data from the old position. `force_raycast_update()` ensures results match the new position.
- `velocity.x = speed * direction` ran unconditionally every frame, immediately overwriting knockback velocity so the hit impulse had zero visible effect and could push the slime back into a wall.

---

## [2026-04-26] - Fix player attack not hitting slime; fix slime flip stutter

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Replaced `get_overlapping_bodies()` poll in `attack()` with a `body_entered` signal connection on `AttackArea`. Damage is now dealt in `_on_attack_area_body_entered` whenever a valid body enters the active attack area.
- Added `_flip_cooldown` timer to Slime. After any direction flip, flipping is blocked for 0.3s, preventing the slime from toggling direction every frame while physically in contact with a wall.

**Reason:**
- `get_overlapping_bodies()` returns an empty array when called the same frame `monitoring` is enabled because the physics engine hasn't processed the new overlap yet. Using `body_entered` fires correctly as soon as the overlap is detected.
- Without a flip cooldown, the slime remained embedded against a wall for several frames after flipping, causing the flip condition to re-trigger immediately and locking the slime in place.

---

## [2026-04-26] - Combat polish: attack cooldown, slime knockback and hurt flash

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Added `ATTACK_COOLDOWN = 0.45s` const and `can_attack` flag to Player. Attack input is blocked while the cooldown is active. Cooldown starts after the swing animation ends.
- Slime: added `@export var knockback_force := 90.0`. On `take_damage`, applies an x-velocity impulse away from the attacker using `direction_to`.
- Slime: added `_flash_hurt()` — creates a Tween that shifts `sprite.modulate` to red (0.05s) then back to white (0.15s) for visual hit feedback without requiring a hurt animation frame.

**Reason:**
Attack spam had no cooldown so a single button press could register as multiple hits. Slime had no visual or physical reaction to being hit, making combat feel unresponsive.

---

## [2026-04-26] - Restart level on player death

**Files Changed:**
- autoload/GameManager.gd
- scripts/player/Player.gd

**Summary:**
- Added `restart_level()` to GameManager: reloads the current level scene using `current_level`.
- `Player.die()` now calls `GameManager.restart_level()` after the "die" animation finishes instead of `queue_free()`.

**Reason:**
The player vanished with no recovery. Restarting the level gives the player another attempt and keeps level-flow logic in GameManager where it belongs.

---

## [2026-04-26] - Fix slime spinning, hurt animation override, player die animation

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Added `is_hurt` and `is_dying` flags to Player.
- `_physics_process` returns early (except `move_and_slide`) when `is_dying`, preventing input after death.
- Player input and velocity are blocked while `is_hurt` or `is_dying`.
- `update_animation` now guards on `is_hurt` and `is_dying` so the hurt/die animations are not overridden each frame.
- `take_damage` guards on `is_dying` so a dead player cannot receive more damage.
- `is_hurt` is cleared after `INVINCIBILITY_DURATION` alongside `is_invincible`.
- `die()` now sets `is_dying`, zeroes velocity, plays "die", awaits `animation_finished`, then calls `queue_free()`.
- Added `_wall_hit()` helper to Slime that returns `false` when the `WallCheck` collider is a `CharacterBody2D`, preventing the slime from treating the player body as a wall and spinning rapidly.

**Reason:**
- `WallCheck` was detecting the player's physics body as a wall, causing the slime to flip every frame when the player stood next to it.
- `update_animation` ran every frame and immediately replaced "hurt" with idle/run/jump because there was no hurt state guard.
- `die()` called `queue_free()` immediately with no animation, making the player vanish with no feedback.

---

## [2026-04-26] - Player health, knockback, and Slime contact damage

**Files Changed:**
- scripts/player/Player.gd
- scripts/enemies/Slime.gd

**Summary:**
- Added `max_hp` export and `hp` variable to Player; initialised in `_ready()`.
- Added `is_invincible` flag, `KNOCKBACK_FORCE` and `INVINCIBILITY_DURATION` constants to Player.
- Added `take_damage(amount: int, from_position: Vector2)` to Player: guards on invincibility, subtracts hp, applies knockback away from the damage source, plays "hurt" animation, starts invincibility window via timer, calls `die()` at zero hp.
- Added `die()` to Player (`queue_free()`).
- Added `@onready var hitbox: Area2D = $Hitbox` to Slime.
- Connected `hitbox.body_entered` in Slime `_ready()`.
- Added `_on_hitbox_body_entered` handler that calls `body.take_damage(damage, global_position)` when the body has the method.

**Reason:**
Player had no health system and Slime's Hitbox was unused. Slime contact damage required the Hitbox Area2D to detect the player and the player needed a health, knockback, and invincibility window to make damage feel fair.

---

## [2026-04-26] - Fix Slime patrol ray origin tracking

**Files Changed:**
- scripts/enemies/Slime.gd

**Summary:**
- Added `wall_check.position.x = 18 * direction` so the WallCheck RayCast2D origin moves to the correct forward edge each frame, matching the direction the slime is travelling.
- Removed `floor_check.target_position` reassignment (value is already correct in the scene and never needs to change at runtime).
- Removed debug `print` statement.

**Reason:**
The WallCheck origin was fixed at `x = -18` (left side) regardless of direction. When the slime moved right, the ray cast from the wrong side and never detected a wall, so the slime would walk through walls and off edges without turning. Moving the origin each frame ensures both the start point and the target direction of the ray always point ahead of the slime.

---
