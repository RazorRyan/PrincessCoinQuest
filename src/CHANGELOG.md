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
