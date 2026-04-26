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
