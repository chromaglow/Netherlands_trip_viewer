# Netherlands Scouting Gallery

A map-driven photo and video gallery documenting a scouting trip through Dutch cities. Every photo and video is plotted on a real map at the exact GPS coordinates where it was taken. Viewers navigate by zooming into cities, clicking pins, and browsing media spatially — seeing not just *what* was photographed but *exactly where*.

Built as a zero-backend static site hosted on Cloudflare Pages. All data lives in flat files — no database, no server, no build step.

---

## Prerequisites

- **Python 3.10+** (tested on 3.13)
- **ffmpeg** — must be installed and on PATH ([ffmpeg.org](https://ffmpeg.org) or `brew install ffmpeg`)
- **Node.js** (optional, for local preview with `npx serve`)

## First-Time Setup

```bash
# Clone the repo
git clone https://github.com/chromaglow/Netherlands_trip_viewer.git
cd Netherlands_trip_viewer

# Create Python virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## API Keys

### Mapbox Token (required for map rendering)

1. Create a free account at [mapbox.com](https://www.mapbox.com)
2. Copy your **Default public token** from the Mapbox dashboard
3. Open `index.html` and replace the placeholder at the top of the `<script>` block:
   ```js
   const MAPBOX_TOKEN = 'YOUR_MAPBOX_TOKEN_HERE';  // ← paste your token here
   ```

> **Free tier:** 50,000 map loads/month — more than enough for personal use.

### Anthropic API Key (required for AI photo tagging)

1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. Create a `.env` file in the project root:
   ```
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```
3. **Never commit this file** — it's already in `.gitignore`

> **Estimated cost:** ~$5 one-time for processing ~340 photos with Claude Sonnet vision.

## Running the Processing Script

The processing script reads raw media from `media-originals/`, extracts GPS and timestamps, reverse-geocodes locations, optimizes images, re-encodes video, and optionally runs AI vision tagging.

```bash
# Process all new files (skips already-processed)
python process.py

# Reprocess everything from scratch
python process.py --force

# Reprocess a single file
python process.py --file IMG_1200.HEIC
```

### What the script does

1. **HEIC → JPEG** conversion (Apple photo format)
2. **EXIF extraction** — GPS coordinates and capture timestamps
3. **Reverse geocoding** via OpenStreetMap Nominatim (1 req/sec throttle)
4. **Image optimization** — display images at 2400px max, thumbnails at 400px, 85% JPEG quality
5. **Video re-encoding** — H.264/MP4 at 1080p max via ffmpeg
6. **Video thumbnails** — first frame extracted as 400px JPEG
7. **AI vision analysis** — Claude Sonnet tags each photo with scene type, urban character, scale, vibe, and theme tags
8. **data.json** — all metadata written to a single flat file

### Output

```
images/display/   ← Web-optimized JPEGs (max 2400px)
images/thumbs/    ← Thumbnails (400px)
video/            ← Re-encoded H.264 MP4s
data.json         ← All metadata for the gallery
large_videos.txt  ← Auto-generated list of videos >23MB (if any)
```

### Terminal output

```
============================================================
PROCESSING COMPLETE
  Processed:        362
  Skipped:          0
  Errors:           0
  Oversized videos: 5
============================================================
```

## Local Preview

```bash
npx serve .
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

> **Note:** The Mapbox token must be set in `index.html` for the map to render.

## Deploying to Cloudflare Pages

1. Push your code to the `main` branch on GitHub
2. Go to [Cloudflare Pages](https://pages.cloudflare.com)
3. Create a new project → Connect to your GitHub repo
4. Settings:
   - **Production branch:** `main`
   - **Build command:** _(leave empty — no build step)_
   - **Build output directory:** `/` (project root)
5. Deploy

Cloudflare Pages will auto-deploy on every push to `main`.

### Custom Domain

1. In your Cloudflare Pages project → Custom Domains
2. Add your domain
3. If using Cloudflare DNS: automatic — no extra config
4. If using external DNS: add the CNAME record shown in the dashboard

### Cache Configuration

The `_headers` file configures Cloudflare caching:
- **Images & video:** immutable, cached for 1 year
- **data.json:** cached for 5 minutes (so edits propagate quickly)

## Using Admin Mode

Admin mode lets you edit captions and tags directly on the live gallery, then download an updated `data.json`.

1. On the gallery page, click the subtle **"Admin"** text at the bottom-left
2. Enter the password (default: `recon2026`) — **change the hash in `index.html` before deploying**
3. Admin mode activates — edit icons appear on all media items
4. Click any item to edit its caption and tags
5. A floating button appears: **"Download data.json (N edits)"**
6. Click it to download the updated file
7. Replace `data.json` in your repo → `git push` → Cloudflare redeploys automatically

> **Security note:** The password is client-side SHA-256 only — appropriate for low-stakes personal content. Admin state is purely in-memory and clears on page reload.

### Changing the Admin Password

1. Choose a new password
2. Generate its SHA-256 hash:
   ```bash
   python -c "import hashlib; print(hashlib.sha256(b'your-new-password').hexdigest())"
   ```
3. Replace the `ADMIN_PASSWORD_HASH` constant in `index.html`

## Oversized Videos

If any re-encoded video exceeds 23MB, its filename is logged to `large_videos.txt`.

For these files, consider:
1. **Leave as-is** — they'll work fine, just slower to load
2. **Upload to Cloudflare Stream** — free up to 1,000 minutes of video
   - Upload manually at [Cloudflare Stream Dashboard](https://dash.cloudflare.com/?to=/:account/stream)
   - Replace the `video_src` in `data.json` with the Stream embed URL

## Project Structure

```
├── index.html            ← Single-file gallery app (HTML + CSS + JS)
├── data.json             ← Generated by process.py
├── narrative.txt         ← Author narrative (static asset)
├── images/
│   ├── display/          ← Web-optimized JPEGs (max 2400px)
│   └── thumbs/           ← Thumbnails (400px)
├── video/                ← Re-encoded H.264 MP4s
├── media-originals/      ← Source files (GITIGNORED)
├── process.py            ← Local processing script
├── requirements.txt      ← Python dependencies
├── _headers              ← Cloudflare Pages cache config
├── large_videos.txt      ← Auto-generated (GITIGNORED)
├── .env                  ← API keys (GITIGNORED)
└── README.md
```

## Branching

- **`main`** — always deployable; Cloudflare Pages deploys from here
- **`dev`** — working branch; merge to `main` when ready to publish
