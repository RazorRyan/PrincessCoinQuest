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
