# PrincessCoinQuest

PrincessCoinQuest is a 2D platformer built with Godot. You play as a princess, collect coins, dodge hazards, and complete platforming sections.

This project started from the Brackeys Godot tutorial:
https://www.youtube.com/watch?v=LOhfqjmasi0

## Table of Contents

- [Game Overview](#game-overview)
- [Controls](#controls)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Run the Project in Godot](#run-the-project-in-godot)
- [Use the Prebuilt HTML5 Version Locally](#use-the-prebuilt-html5-version-locally)
- [Export Builds from Godot](#export-builds-from-godot)
- [Deploy `binaries/HTML5` to Cloudflare Pages](#deploy-binarieshtml5-to-cloudflare-pages)
- [Troubleshooting](#troubleshooting)

## Game Overview

- **Genre:** 2D platformer
- **Engine:** Godot 4.x (`src/project.godot` currently targets 4.6 features)
- **Core loop:** Move, jump, collect coins, avoid enemies and kill zones
- **Score system:** Coin pickups increase the score displayed in the UI

## Controls

Default keyboard controls configured in `src/project.godot`:

- **Move Left:** `A` or Left Arrow
- **Move Right:** `D` or Right Arrow
- **Jump:** `Space`

## Repository Structure

- `src/` - Main Godot project (scenes, scripts, assets, export presets)
- `src/scenes/` - Game scenes (player, level, enemies, collectibles, etc.)
- `src/scripts/` - GDScript logic for gameplay systems
- `binaries/HTML5/` - Prebuilt web export files
- `binaries/Windows/` - Prebuilt Windows executables

## Requirements

Depending on what you want to do:

### Play / preview the prebuilt HTML5 game

- Node.js + npm (only needed to use `npm run preview`)

### Edit or export the game

- Godot 4.x (matching the project configuration is recommended)

### Deploy to Cloudflare Pages

- Cloudflare account
- Wrangler CLI (optional, for CLI deployment)

## Run the Project in Godot

1. Open Godot.
2. Import the project at `src/project.godot`.
3. Run the main scene from the editor.

## Use the Prebuilt HTML5 Version Locally

The repository already includes a web build in `binaries/HTML5`.

From `binaries/HTML5`:

```bash
npm install
npm run preview
```

Then open:
`http://localhost:8080/PrincessCoinQuest.html`

## Export Builds from Godot

Export presets are defined in `src/export_presets.cfg` (Web and Windows Desktop presets are included).

1. Open the project in Godot.
2. Go to **Project -> Export**.
3. Select the target preset (for example, **Web** or **Windows Desktop**).
4. Export to your preferred output directory.

## Deploy `binaries/HTML5` to Cloudflare Pages

This project already contains a ready-to-deploy web build in:
`binaries/HTML5`

### Option 1: Deploy with the Cloudflare Dashboard

1. Sign in to Cloudflare and go to **Workers & Pages**.
2. Click **Create application** > **Pages** > **Upload assets**.
3. Create a new Pages project (or select an existing one).
4. Upload all files from `binaries/HTML5/`.
5. Deploy.

After deployment, open:
`https://<your-project>.pages.dev/PrincessCoinQuest.html`

### Option 2: Deploy with Wrangler CLI

1. Install dependencies (if needed):
   ```bash
   cd binaries/HTML5
   npm install
   ```
   This installs Wrangler from the local `devDependencies` so it can be run with `npx`.
2. Log in to Cloudflare:
   ```bash
   npx wrangler login
   ```
3. Deploy:
   ```bash
   npx wrangler pages deploy . --project-name princesscoinquest
   ```

### Optional: Serve the game at the root URL

Cloudflare Pages serves `index.html` at `/`, but this export uses `PrincessCoinQuest.html`.

If you want the game to open at the root URL:

```bash
cp binaries/HTML5/PrincessCoinQuest.html binaries/HTML5/index.html
```

Then redeploy the same folder.

## Troubleshooting

- **Blank page or missing assets in web build**
  - Make sure all files from `binaries/HTML5/` were uploaded together.
- **Wrong URL after deployment**
  - Try `/PrincessCoinQuest.html` unless you created `index.html`.
- **Controls not responding**
  - Click inside the game canvas to focus input.
