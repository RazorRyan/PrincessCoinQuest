# Princess Coin Quest — Copilot Instructions

You are assisting with a Godot 4 2D action platformer.

## 🎯 Game Overview

This is a 2D side-scrolling action platformer.

Core gameplay:
- Player controls a princess
- Collect coins
- Kill enemies
- Unlock exit
- Progress through levels

## 🧱 Architecture Rules

Do NOT restructure the entire project unless explicitly asked.

Follow this structure:

res://
- assets/
- autoload/
- scenes/
- scripts/
- data/

Use reusable scenes for all gameplay elements.

## 🎮 Scene Rules

Each object must be its own reusable scene:

Player.tscn = CharacterBody2D  
Slime.tscn = CharacterBody2D  
Coin.tscn = Area2D  
ExitDoor.tscn = Area2D  
HUD.tscn = CanvasLayer  
Level scenes = Node2D  

Script `extends` MUST match root node type.

## 🗺️ Level Design Rules

Levels must be created by duplicating a template.

Each level contains:

LevelXX (Node2D)
- ParallaxBackground (optional)
- TileMapLayer / TileMap
- Player
- Coins (container)
- Enemies (container)
- ExitDoor
- Camera2D
- HUD

Coins and Enemies are containers only.

No gameplay logic should be hardcoded per level.

## 💰 Game Rules

- Player must collect ALL coins to unlock exit
- Exit is locked until all coins are collected
- Touching exit loads next level
- If no next level exists → game complete

## 🧠 GameManager Rules

GameManager is an Autoload.

Responsibilities:
- Track coins collected
- Track total coins
- Emit signals when coins change
- Emit signal when all coins collected
- Handle level progression

Use signals instead of direct references.

## 👤 Player Rules

Player handles ONLY:
- Movement
- Jumping
- Attacking
- Taking damage
- Animation

Player must NOT:
- Control level flow
- Count coins
- Manage UI

Required animations:
idle, run, jump, attack, hurt

## 🪙 Coin Rules

Coin must:
- Be Area2D
- Detect player overlap
- Call GameManager.collect_coin()
- Remove itself safely

Optional:
- Play sound
- Play animation

## 👾 Enemy Rules

Enemies must:
- Be CharacterBody2D
- Have their own CollisionShape2D (body)
- Have separate hitbox if needed

Slime behavior:
- Patrol left/right
- Turn when hitting wall
- Turn before falling off edge
- Take damage
- Die cleanly

Use:
- 1 WallCheck (RayCast2D)
- 1 FloorCheck (RayCast2D)

Movement must use:
velocity + move_and_slide()

NOT position-based movement.

## 🧱 Collision Rules

- CharacterBody2D must have direct CollisionShape2D
- Hitboxes must not replace body collision
- TileMap must have physics shapes
- Collision layers/masks must match

## 🧱 TileMap Rules

- One rectangle collision per solid tile
- No collision on decorative tiles

## 🎨 Animation Rules

AnimatedSprite2D must have correct animation names.

Never call sprite.play() with missing animations.

## 📱 Mobile Considerations

- Controls must be touch-friendly
- UI must not block gameplay
- Camera should be smooth

## 🧠 Coding Rules

- Keep scripts small and focused
- Use @export for tuning values
- Use @onready for node references
- Use signals for communication

Avoid:
- Large monolithic scripts
- Hardcoded paths across scenes
- Duplicated logic

## ⚠️ Safety Rules

Before making changes:
1. Explain what will change
2. Explain why

After changes:
1. Summarize changes
2. Explain how to test in Godot

Never break existing working systems.

## 🚀 Current Priority

1. Player movement stability
2. Coin collection + HUD
3. Enemy patrol behavior
4. Exit unlocking
5. Level progression
6. Mobile controls
7. Game feel polish