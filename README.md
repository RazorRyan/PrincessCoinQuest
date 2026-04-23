# PrincessCoinQuest

PrincessCoinQuest is a 2D platformer built with Godot. You play as a princess, collect coins, avoid hazards, and navigate platforming sections while enemies patrol the level.

This project was inspired by the Brackeys Godot tutorial:
https://www.youtube.com/watch?v=LOhfqjmasi0

## Gameplay Overview

- Move through the level using left/right movement.
- Jump across platforms and gaps.
- Collect coins to increase your score.
- Avoid enemies and kill zones, which trigger a death/reset flow.

## Controls

- **Move left:** `A` or `Left Arrow`
- **Move right:** `D` or `Right Arrow`
- **Jump:** `Space`

## Repository Layout

- `src/` - Main Godot project (scenes, scripts, assets, project settings)
- `src/scenes/` - Game scenes (player, game, coin, enemies, hazards)
- `src/scripts/` - GDScript gameplay logic
- `binaries/HTML5/` - Exported HTML5/Web build output
- `binaries/Windows/` - Exported Windows build output

## Requirements

- **Godot 4.6** (project features target 4.6)
- **Node.js + npm** (only needed for local HTML5 preview/deployment helpers)

## Run the Project Locally (Godot)

1. Open Godot 4.6.
2. Import the project from:
   `src/project.godot`
3. Run the main scene from the editor.

## Run the HTML5 Build Locally

The repository already includes a pre-exported web build in `binaries/HTML5/`.

```bash
cd binaries/HTML5
npm install
npm run preview
```

Then open:
`http://localhost:8080/PrincessCoinQuest.html`

## Deploy `binaries/HTML5` to Cloudflare Pages

### Option 1: Cloudflare Dashboard

1. Sign in to Cloudflare and open **Workers & Pages**.
2. Click **Create application** > **Pages** > **Upload assets**.
3. Create/select a Pages project.
4. Upload all files from `binaries/HTML5/`.
5. Deploy.

After deployment, open:
`https://<your-project>.pages.dev/PrincessCoinQuest.html`

### Option 2: Wrangler CLI

```bash
npm install -g wrangler
wrangler login
wrangler pages deploy binaries/HTML5 --project-name princesscoinquest
```

## Optional: Serve the Game from Root (`/`)

Cloudflare Pages serves `index.html` at `/`, while this build uses `PrincessCoinQuest.html`.

If you want the game at the site root:

```bash
cp binaries/HTML5/PrincessCoinQuest.html binaries/HTML5/index.html
```

Then redeploy `binaries/HTML5/`.
