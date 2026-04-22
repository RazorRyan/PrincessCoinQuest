# PrincessCoinQuest

PrincessCoinQuest is a 2D platformer made with Godot. You play as a princess collecting coins across handcrafted levels while avoiding hazards and navigating platforming challenges.

The game was created by following the Brackeys Godot tutorial:
https://www.youtube.com/watch?v=LOhfqjmasi0

## Project Structure

- `src/` - Godot project files (scenes, scripts, assets)
- `binaries/HTML5/` - Web build output
- `binaries/Windows/` - Windows build output

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

1. Install Wrangler:
   ```bash
   npm install -g wrangler
   ```
2. Log in to Cloudflare:
   ```bash
   wrangler login
   ```
3. Deploy the HTML5 output folder:
   ```bash
   wrangler pages deploy binaries/HTML5 --project-name princesscoinquest
   ```

### Optional: Serve the game at the root URL

Cloudflare Pages serves `index.html` at `/`. This build uses `PrincessCoinQuest.html`.

If you want the game to open at the root URL, rename the file before deploying:

```bash
cp binaries/HTML5/PrincessCoinQuest.html binaries/HTML5/index.html
```

Then redeploy the same folder.
