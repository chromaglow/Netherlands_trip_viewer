# Project Spec: Netherlands Scouting Gallery
### Final v1.0 — LOCKED

---

## 1. Plain-English Summary

A beautiful, map-driven photo and video gallery documenting a scouting trip through Dutch cities. The gallery is hosted as a free static website and serves two audiences: a primary partner using it to evaluate potential relocation destinations, and a broader group following the trip.

Every photo and video is plotted on a real map at the GPS coordinates where it was taken. Viewers navigate by zooming into cities, clicking pins, and browsing media spatially — seeing not just *what* was photographed but *exactly where*. An AI processing pipeline (run once locally before publishing) extracts location data, generates descriptive tags, and produces draft captions informed by the author's written narrative about Dutch life and culture.

The city list is not hardcoded — it is discovered dynamically from the GPS metadata of the photos themselves at processing time. The gallery adapts to whatever cities are represented in the media.

The author can edit captions and tags via a password-protected admin overlay on the live site, then download an updated data file and redeploy with one push.

---

## 2. Goals & Non-Goals

### Goals
- Publish ~375 photos and videos from a Netherlands scouting trip as a navigable, map-driven gallery
- Give viewers spatial context: *where* in each city each shot was taken
- Enable thematic discovery: filter by topic (e.g. "bike infrastructure") to compare across all cities simultaneously
- Provide the author a way to edit captions and tags without touching code
- Display the author's narrative essay alongside the media
- Host entirely for free (or near-free) with no ongoing server costs
- Keep the city list and all taxonomy fully data-driven — no hardcoded city names anywhere in the app

### Non-Goals
- No user accounts, comments, or social features
- No real-time updates or live feed
- No CMS or database — all content lives in flat files
- No mobile app — web only (must work well on mobile browser)
- Visual design system (Phase 7) is out of scope for this coding spec — placeholder styling only

---

## 3. Users & User Stories

### Personas
1. **Primary Partner** — close viewer using the gallery to help evaluate Dutch cities for relocation. Wants to understand neighborhood character, scale, density, and livability across cities.
2. **Broader Followers** — friends, family, and interested parties following the trip. Want to browse and discover interesting photos.
3. **Author/Editor** — the person who took the photos and wrote the narrative. Needs to manage captions and tags post-publish.

### User Stories
1. **As a primary viewer**, I want to zoom into a city on the map and see where every photo was taken at street level, so I can understand the spatial distribution of what was documented.
2. **As a viewer**, I want to filter by "bike infrastructure" and see every photo and video tagged with that theme across all cities, so I can directly compare how each city handles it.
3. **As the author**, I want to log into an admin overlay, click a photo, fix its caption, and download the updated data file — without touching any code.

---

## 4. MVP Scope (Must-Have)

- [ ] **Processing script** — runs locally, produces `data.json` from media folder
  - EXIF extraction (GPS, timestamp)
  - City/neighborhood/street discovery via Nominatim reverse geocoding (no hardcoded city list)
  - Video re-encoding to web-optimized H.264/MP4 via ffmpeg
  - Vision AI tagging (scene type, urban character, scale, vibe, human presence)
  - Theme tag generation cross-referenced with `narrative.txt`
  - Draft caption generation per media item where thematic connection found
- [ ] **Map view** — Mapbox GL JS, full Netherlands extent on load
  - Photo pins (amber) and video pins (teal)
  - City-level clustering with count badges
  - Zoom to expand clusters → individual pins at GPS coordinates
- [ ] **Expanded media view** — split screen (map left 1/3, media right 2/3)
  - Photo display with metadata (city, neighborhood, street, date, time, caption)
  - Video inline playback
  - Left/right arrow navigation; active map pin updates as user navigates
  - When current pin exhausted, advance to geographically nearest pin with map animation
- [ ] **Similar media row** — horizontal thumbnail strip at bottom of expanded view
  - Pulled by matching theme tags + scene type across other cities
  - Match threshold stored as a named constant (easy to tune)
- [ ] **Filter panel** — slide-in drawer
  - Filter by: city, media type (photo/video), scene type, theme
  - City options populated dynamically from `data.json` (not hardcoded)
  - Filter state reflected in URL query params (shareable filtered views)
- [ ] **Caption admin mode**
  - Password-protected overlay (hardcoded password constant in JS)
  - Click any media item → edit caption, edit/add/remove tags
  - "Download updated data.json" button
- [ ] **Narrative display** — readable text view accessible from the gallery
- [ ] **Deployment** — Cloudflare Pages from GitHub repo, custom domain

---

## 5. Later Scope (Nice-to-Have)

- Satellite/hybrid map toggle (Mapbox supports this)
- Lightbox / full-screen photo view
- Keyboard navigation (arrow keys, Escape)
- "Hide this item" toggle in admin mode (soft-delete without removing from data.json)
- Reorder media items within a pin in admin mode
- Cloudflare Stream integration for any video that exceeds 23MB after re-encoding
- Batch caption regeneration (re-run AI on specific items after narrative.txt is expanded)
- Search by keyword across all tags and captions
- Timeline view (browse by date instead of map)
- Final visual design system (Phase 7 — separate design conversation)

---

## 6. User Flow / Workflow

### Viewer — Primary Flow
1. Land on full-map view; city clusters visible
2. Zoom into a city → clusters expand into individual pins
3. Click a pin → split screen opens; media on right, map on left
4. Read caption + metadata; if video, it plays inline
5. Arrow right → next media item at same pin; map pin pulses
6. Arrow right past last item at pin → nearest pin advances; map animates
7. Scroll to bottom of media panel → "Similar shots from other cities" row appears
8. Click a thumbnail → navigate to that item in split screen

### Viewer — Thematic Discovery Flow
1. Click filter icon on map view
2. Select theme tag (e.g. "bike infrastructure")
3. Map updates to show only pins matching that theme
4. Browse filtered results spatially or enter expanded view

### Author — Caption Editing Flow
1. Navigate to the live gallery URL and enter admin password in overlay
2. Admin mode activates; edit icons appear on all media items
3. Click any item → inline edit panel opens (caption field, tag chips)
4. Edit, save locally in memory
5. Click "Download data.json" → updated file downloads
6. Drop file in local repo → `git push` → Cloudflare redeploys automatically

### Author — Processing Script Flow (one-time + re-run)
1. Place all media in `/media-originals/` folder
2. Ensure `narrative.txt` is written and placed in project root
3. Run `python process.py`
4. Script re-encodes videos → `/video/`, converts/optimizes photos → `/images/`
5. Script calls Nominatim for each GPS coordinate (discovers cities dynamically)
6. Script calls Claude API for each photo (vision + tags + draft caption)
7. `data.json` written to project root
8. Review output; re-run on specific files if needed with `--file [filename]`

---

## 7. Functional Requirements

### Processing Script (`process.py`)
- FR-01: Read all files from `/media-originals/` (HEIC, JPG, PNG, MOV, MP4)
- FR-02: Extract EXIF GPS coordinates and timestamp from each file using `Pillow` + `piexif`
- FR-03: Convert HEIC to JPG automatically using `pillow-heif`
- FR-04: Reverse geocode GPS → street, neighborhood, city using Nominatim with 1 req/sec throttle (per OSM policy); city name comes from geocoder response, never from a hardcoded list
- FR-05: Re-encode all video to H.264/MP4 at 1080p max using `ffmpeg-python`; any output file >23MB is flagged to `large_videos.txt` log
- FR-06: Call Claude API (claude-sonnet) vision on each photo with: (a) the image, (b) the tag taxonomy prompt, (c) the relevant city section of `narrative.txt`; receive structured JSON response
- FR-07: Generate theme tags by cross-referencing AI output with themes found in `narrative.txt`
- FR-08: Produce draft caption only when AI finds thematic connection; leave null otherwise
- FR-09: Write `data.json` with one entry per media file (schema below)
- FR-10: Skip already-processed files on re-run (check filename against existing `data.json`); `--force` flag reprocesses all; `--file [name]` reprocesses one file
- FR-11: Extract first-frame thumbnail from each video using ffmpeg for use in pins and similar-shots row
- FR-12: Print progress to terminal with counts and any errors; on completion print summary (processed, skipped, errors, oversized videos)

### Map View
- FR-13: Load `data.json` on page init; render Mapbox GL JS map centered on Netherlands
- FR-14: Render photo pins (amber) and video pins (teal) at GPS coordinates
- FR-15: Cluster pins by proximity at low zoom; show count badge; expand to individual pins at high zoom
- FR-16: Filter panel slide-in drawer with checkboxes for: city, media type, scene type, theme — all options populated dynamically from `data.json`, not hardcoded
- FR-17: Applying a filter re-renders only matching pins; non-matching pins hidden
- FR-18: Filter state serialized to URL query params; loading a URL with params restores filter state

### Expanded Media View
- FR-19: Clicking a pin opens split-screen; map at left 1/3, media panel at right 2/3
- FR-20: Display photo or inline `<video>` in media panel
- FR-21: Metadata strip: city, neighborhood, street, date, time of day, caption (author_caption if present, else draft_caption, else empty)
- FR-22: Left/right arrows navigate through media at current pin; active pin pulses on map
- FR-23: Advancing past last item at a pin → find nearest pin by Haversine distance → fly map to it → load its first item
- FR-24: Similar shots row: query `data.json` client-side for items sharing ≥1 theme tag AND same scene_type, from a different city; show up to 8 thumbnails at 400px; clicking navigates to that item
- FR-25: **SIMILAR_MATCH_THRESHOLD** and **SIMILAR_MAX_RESULTS** are named constants at top of JS file, clearly labeled as tunable

### Admin Mode
- FR-26: Password prompt modal on activation; password compared against SHA-256 hash of the ADMIN_PASSWORD constant
- FR-27: Correct password activates admin mode; edit icons appear on all media items
- FR-28: Edit panel: caption textarea, tag chip editor (add/remove), save/cancel per item
- FR-29: All edits held in a single in-memory diff object (keyed by media id)
- FR-30: "Download data.json" button merges diff into full dataset and triggers browser file download
- FR-31: Admin mode leaves no persistence after page reload; purely client-side

### Narrative View
- FR-32: Fetch `narrative.txt` as a static asset; display in a readable centered text panel (max 700px wide)
- FR-33: Auto-detect city headings from the text (lines matching known city names from data.json, or ALL-CAPS lines)
- FR-34: Accessible via "Narrative" button in top nav; dismissable

---

## 8. Non-Functional Requirements

- **Performance:** Page load < 3 seconds on standard broadband. Map tiles load progressively. Images lazy-loaded.
- **Image optimization:** Display images output at 85% JPEG quality, max 2400px on longest side. Thumbnails at 400px.
- **Security:** Admin password is client-side SHA-256 only — appropriate for low-stakes personal content.
- **Browser support:** Modern browsers only (Chrome, Firefox, Safari, Edge — current versions).
- **Mobile:** Responsive. Split-screen collapses to stacked layout at < 768px wide.
- **Repo size:** Target < 1GB. Processing script flags oversized videos for manual Cloudflare Stream handling.

---

## 9. Data Model

### `data.json` top-level
```json
{
  "generated_at": "ISO timestamp",
  "media": [ ...array of MediaEntry objects... ]
}
```

### MediaEntry schema
```json
{
  "id": "unique string (filename without extension)",
  "filename": "DSC_0042.jpg",
  "media_type": "photo" | "video",
  "city": "Rotterdam",
  "neighborhood": "Kralingen",
  "street": "Straatweg",
  "date": "2026-04-14",
  "time_of_day": "morning" | "afternoon" | "evening" | "night",
  "gps": { "lat": 51.9225, "lng": 4.4792 },
  "tags": {
    "scene_type": ["canal", "street"],
    "urban_character": ["dense", "residential"],
    "scale": ["human-scaled"],
    "vibe": ["historic", "quiet"],
    "human_presence": "low"
  },
  "theme_tags": ["bike infrastructure", "street scale"],
  "draft_caption": "AI-generated string or null",
  "author_caption": "Author-edited string or null",
  "thumbnail": "images/thumbs/DSC_0042.jpg",
  "display_src": "images/display/DSC_0042.jpg",
  "video_src": "video/DSC_0042.mp4"
}
```

**Caption resolution rule (JS):** `author_caption ?? draft_caption ?? ""`

---

## 10. External Integrations

| Service | Purpose | Cost | Notes |
|---|---|---|---|
| Mapbox GL JS | Map rendering | Free (50k loads/mo) | Free API key required |
| Nominatim (OSM) | Reverse geocoding | Free | 1 req/sec; script throttles |
| Claude API | Vision tagging + captions | ~$5 one-time est. | Key in `.env`; never committed |
| Cloudflare Pages | Static hosting + CDN | Free | Auto-deploy from GitHub `main` |
| ffmpeg | Video re-encoding | Free (local) | Must be installed on author's machine |
| Cloudflare Stream | Oversized video fallback | Free up to 1k min | Manual upload only if flagged |

---

## 11. UX Notes / Screens

### Screen 1 — Map View (entry)
- Full-viewport Mapbox map, centered on Netherlands
- Top bar: gallery title, filter button, narrative button
- Amber pins = photo, teal pins = video; cluster badges show count

### Screen 2 — Split Screen (media expanded)
- Left 33%: map with active pin pulsing
- Right 67%: media, metadata strip, nav arrows, similar-shots row
- Close button returns to full map
- Mobile (< 768px): stacked — media top, mini-map below

### Screen 3 — Filter Panel
- Slide-in drawer (left side)
- Checkboxes grouped: City / Media Type / Scene Type / Theme
- All options from `data.json`, not hardcoded
- "Clear all" button; URL query param sync

### Screen 4 — Narrative View
- Centered readable panel, max 700px wide
- City headings auto-detected
- Accessible from top nav; dismissable overlay

### Screen 5 — Admin Overlay
- Password modal on activation
- Edit icons on all media items
- Edit panel per item: caption textarea + tag chip editor
- Floating "Download data.json" button when unsaved edits exist

---

## 12. Technical Architecture

```
nl-scouting-gallery/
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
├── large_videos.txt      ← Auto-generated; lists files >23MB after encode
├── .gitignore
└── README.md
```

**Runtime:** Browser fetches `data.json` + `narrative.txt` → all logic runs client-side. Zero server calls at runtime.

**Processing:** Runs locally on author's machine before deploy. Output committed to repo. Re-run anytime with `--file` for individual updates.

---

## 13. Repo Plan

**Repo name:** `nl-scouting-gallery`

### Local dev setup
```bash
git clone https://github.com/[your-username]/nl-scouting-gallery
cd nl-scouting-gallery
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
# Install ffmpeg system-wide: brew install ffmpeg (mac) or ffmpeg.org (windows)
python process.py               # run processing script
npx serve .                     # local preview (requires Node)
```

### Branching
- `main` — always deployable; Cloudflare Pages deploys from here
- `dev` — working branch; merge to `main` to publish

### Commit milestones
- `M1: scaffold` — folder structure, .gitignore, README stub
- `M2: processing-script` — process.py tested on sample media
- `M3: map-foundation` — Mapbox renders, all pins from data.json
- `M4: expanded-view` — split-screen, navigation, map sync
- `M5: similar-media-and-filters` — similar row, filter panel, URL params
- `M6: admin-mode` — edit overlay, download data.json
- `M7: narrative-view` — narrative text panel
- `M8: deployment` — Cloudflare Pages config, custom domain, final README

---

## 14. Implementation Plan (Milestones)

### M1 — Scaffold
- Git repo init, folder structure, `.gitignore` (exclude `media-originals/`, `venv/`, `.env`)
- Empty `index.html`, `process.py`, `requirements.txt`
- README with project description and setup placeholder

### M2 — Processing Script
- EXIF extraction: `Pillow`, `piexif`, `pillow-heif` (HEIC support)
- Nominatim geocoding with 1 req/sec throttle; city derived from response
- ffmpeg video re-encoding to H.264/MP4 1080p max; flag >23MB to `large_videos.txt`
- First-frame video thumbnail extraction via ffmpeg
- Image optimization: display (2400px max, 85% JPEG) + thumbnail (400px)
- Claude API vision call with structured JSON prompt; narrative.txt city-section extraction
- Theme tag cross-reference logic
- `data.json` writer with skip-processed and `--force` / `--file` flags
- Terminal progress + completion summary

### M3 — Map Foundation
- Mapbox GL JS in `index.html`; `data.json` loaded on init
- Pin rendering: amber (photo), teal (video)
- Clustering + count badges; zoom expand behavior
- Top nav bar: title, filter button, narrative button

### M4 — Expanded Media View
- Split-screen layout (33/67); responsive stacked at <768px
- Photo display + inline video playback
- Metadata strip (all fields from data.json entry)
- Left/right arrow navigation; pin pulse animation
- Haversine nearest-pin logic; Mapbox `flyTo` animation on advance
- Close button → return to full map

### M5 — Similar Media Row + Filter Panel
- **SIMILAR_MATCH_THRESHOLD** (default: 1 shared theme tag + same scene_type) and **SIMILAR_MAX_RESULTS** (default: 8) as named constants
- Client-side tag matching query; horizontal 400px thumbnail strip
- Filter slide-in drawer; all options from `data.json` (dynamic)
- Pin visibility toggling on filter apply
- URL query param serialization/restoration

### M6 — Caption Admin Mode
- **ADMIN_PASSWORD_HASH** constant (SHA-256 of `recon2026` — change before deploy)
- Password modal; hash comparison on submit
- Edit icons in admin mode; per-item edit panel (caption + tag chips)
- In-memory diff object keyed by media `id`
- "Download data.json" button: merge diff → trigger download
- Floating button shows unsaved edit count badge

### M7 — Narrative View
- Fetch `narrative.txt` static asset
- Auto-detect headings (city names from `data.json` or ALL-CAPS lines)
- Centered readable panel (max 700px); open/close from top nav

### M8 — Deployment
- `_headers` file for Cloudflare Pages (cache headers for images/video)
- Cloudflare Pages project: connect GitHub repo, set `main` as deploy branch
- Custom domain DNS setup instructions in README
- Full README: setup, script usage, re-run instructions, admin usage, deployment notes

---

## 15. Acceptance Criteria

### Processing Script
- [ ] `python process.py` on 10 test files (mix of JPG, HEIC, MOV) produces valid `data.json` with one entry per file
- [ ] All entries have GPS coordinates, city (from geocoder), neighborhood, and ≥3 AI tags
- [ ] Videos re-encoded to MP4; originals untouched in `media-originals/`
- [ ] Files >23MB after encoding appear in `large_videos.txt`
- [ ] Re-run skips already-processed files; `--force` reprocesses all; `--file` reprocesses one
- [ ] No hardcoded city names anywhere in script

### Map View
- [ ] Gallery loads with no console errors
- [ ] All pins render at correct GPS coordinates
- [ ] Clustering and zoom-expand behavior works
- [ ] Photo and video pins visually distinct
- [ ] Filter panel options are populated from `data.json` (test by adding a new city — it should appear)

### Expanded View
- [ ] Clicking a pin opens split-screen
- [ ] Navigation updates active map pin
- [ ] Advancing past last item at a pin moves to nearest pin with animation
- [ ] Videos play inline
- [ ] Similar shots row shows items from a different city with matching tags
- [ ] SIMILAR_MATCH_THRESHOLD change (e.g. to 2) correctly reduces results

### Admin Mode
- [ ] Correct password activates admin mode; wrong password does not
- [ ] Caption edit reflects immediately in media view
- [ ] Downloaded `data.json` is valid JSON with edits applied
- [ ] Page reload clears admin state entirely

### Deployment
- [ ] Push to `main` triggers Cloudflare Pages deploy
- [ ] Gallery accessible at custom domain over HTTPS
- [ ] All media loads correctly from CDN

---

## 16. Open Questions / Assumptions

| # | Item | Status |
|---|---|---|
| 1 | Mapbox API key | **Action (author):** Create free account at mapbox.com; paste key into `index.html` constant before deploy |
| 2 | Claude API key | **Action (author):** Store in `.env` as `ANTHROPIC_API_KEY`; never commit to repo |
| 3 | `narrative.txt` | **Assumed absent at first run:** Script handles gracefully — skips theme generation, logs warning; re-run after narrative is written |
| 4 | Admin password | **Default:** `recon2026` — change `ADMIN_PASSWORD_HASH` constant before deploying |
| 5 | City list | **Fully dynamic:** Derived from Nominatim responses at process time; no city names hardcoded anywhere in app or script |
| 6 | Cloudflare Stream | **Deferred:** Set up manually if `large_videos.txt` has entries after processing |
| 7 | HEIC conversion | **Assumed:** All HEIC converted to JPEG by script; originals preserved |
| 8 | Design system | **Out of scope:** Phase 7 is a separate design conversation; placeholder styling only for this build |
| 9 | Video thumbnails | **Assumed:** First-frame extracted by ffmpeg; used for pin display and similar-shots row |

---
---

# Coding Agent Handoff Prompt (Claude in VSCode / Cursor)

```
You are a senior software engineer building the `nl-scouting-gallery` project end-to-end.
You will implement this project exactly as specified, milestone by milestone, making no
assumptions beyond what is stated. If a genuine blocking ambiguity arises, stop and ask.
Otherwise, proceed using the stated defaults.

---

## PROJECT OVERVIEW

A static map-driven photo/video gallery for a Netherlands scouting trip.
- Hosted on Cloudflare Pages (GitHub → auto-deploy)
- Single HTML/CSS/JS file (`index.html`) + flat file assets
- Local Python processing script (`process.py`) generates all metadata
- No backend, no database, no build step
- All city/tag/filter data is fully dynamic from `data.json` — nothing hardcoded

---

## REPO SETUP

1. Initialize a new git repo named `nl-scouting-gallery`
2. Create this exact folder structure:

```
nl-scouting-gallery/
├── index.html
├── data.json             (empty array placeholder until script runs)
├── narrative.txt         (empty placeholder)
├── images/
│   ├── display/
│   └── thumbs/
├── video/
├── media-originals/      (GITIGNORED — user places source files here)
├── process.py
├── requirements.txt
├── large_videos.txt      (auto-generated by script)
├── _headers              (Cloudflare Pages cache config)
├── .gitignore
└── README.md
```

3. `.gitignore` must exclude: `media-originals/`, `venv/`, `.env`, `__pycache__/`, `*.pyc`, `large_videos.txt`
4. Initial commit: `M1: scaffold`

---

## MILESTONE INSTRUCTIONS

Implement one milestone at a time. Commit after each with the milestone tag.

---

### M2 — Processing Script (`process.py`)

**Dependencies (write to `requirements.txt`):**
- Pillow
- pillow-heif
- piexif
- requests
- ffmpeg-python
- anthropic

**Script behavior:**
- Reads all files from `media-originals/` (extensions: .jpg .jpeg .png .heic .mov .mp4)
- Extracts GPS + timestamp EXIF using Pillow + piexif
- Converts HEIC → JPEG using pillow-heif before any other processing
- Reverse geocodes each GPS coordinate using Nominatim (https://nominatim.openstreetmap.org/reverse)
  - Throttle to 1 request/second (required by OSM usage policy)
  - Extract: city (address.city or address.town or address.village), neighbourhood, road
  - City name comes ONLY from geocoder response — never from any hardcoded list
- For photos: optimize to JPEG 85% quality, max 2400px longest side → `images/display/`
  - Also generate 400px thumbnail → `images/thumbs/`
- For videos: re-encode to H.264/MP4 at 1080p max using ffmpeg
  - Output to `video/`
  - If output file size > 23MB: append filename to `large_videos.txt`; still output the file
  - Extract first frame as 400px JPEG thumbnail → `images/thumbs/[filename].jpg`
- Calls Claude API (model: `claude-opus-4-5`, vision) for each PHOTO (not video) with:
  - The image as base64
  - This tag taxonomy prompt (structured JSON response requested):
    ```
    Analyze this photo and return ONLY a JSON object with these fields:
    {
      "scene_type": [list from: canal, street, market, waterfront, interior, transit, food, architecture, park],
      "urban_character": [list from: dense, open, residential, commercial, industrial],
      "scale": [list from: narrow, wide, human-scaled, monumental],
      "vibe": [list from: quiet, busy, historic, modern, gritty, polished],
      "human_presence": one of: none, low, medium, high,
      "theme_tags": [list of thematic tags found in the narrative context below],
      "draft_caption": "one sentence caption if a strong thematic connection exists, else null"
    }
    ```
  - The relevant city section of `narrative.txt` appended as context (if file exists)
  - If `narrative.txt` does not exist: skip theme_tags and draft_caption; log a warning once
- Reads API key from environment variable `ANTHROPIC_API_KEY` (never hardcoded)
- Writes `data.json` with schema:
  ```json
  {
    "generated_at": "<ISO timestamp>",
    "media": [
      {
        "id": "<filename without extension>",
        "filename": "<original filename>",
        "media_type": "photo" | "video",
        "city": "<from geocoder>",
        "neighborhood": "<from geocoder or null>",
        "street": "<from geocoder or null>",
        "date": "YYYY-MM-DD",
        "time_of_day": "morning" | "afternoon" | "evening" | "night",
        "gps": { "lat": float, "lng": float },
        "tags": {
          "scene_type": [],
          "urban_character": [],
          "scale": [],
          "vibe": [],
          "human_presence": ""
        },
        "theme_tags": [],
        "draft_caption": null,
        "author_caption": null,
        "thumbnail": "images/thumbs/<filename>.jpg",
        "display_src": "images/display/<filename>.jpg",
        "video_src": "video/<filename>.mp4"  // only for video
      }
    ]
  }
  ```
- **Skip logic:** On re-run, read existing `data.json`; skip any file whose `id` already exists
- **CLI flags:**
  - `--force` — reprocess all files regardless of existing data.json
  - `--file <filename>` — reprocess a single file by name
- **Terminal output:** Progress per file, final summary: "Processed: X | Skipped: Y | Errors: Z | Oversized videos: W"
- Time-of-day derivation from timestamp: 5–11 = morning, 12–16 = afternoon, 17–20 = evening, 21–4 = night

Commit: `M2: processing-script`

---

### M3 — Map Foundation (`index.html`)

Build the map view as a single self-contained HTML file.

**Map:**
- Mapbox GL JS (load from CDN)
- `MAPBOX_TOKEN` constant at top of `<script>` block — clearly labeled for user to fill in
- On load: fetch `data.json`; initialize map centered on Netherlands (lng: 5.2913, lat: 52.1326, zoom: 7)
- Render photo pins (amber: `#F59E0B`) and video pins (teal: `#14B8A6`) at GPS coordinates
- Use Mapbox GeoJSON source + symbol or circle layers
- Clustering: enable Mapbox built-in clustering; show count badge on clusters
- Zoom ≥ 10: clusters expand to individual pins

**Top nav bar:**
- Gallery title (left)
- "Filter" button (center-right)
- "Narrative" button (right)

**Styling:** Placeholder only — clean, minimal, functional. Dark map style preferred (`mapbox://styles/mapbox/dark-v11`).

Commit: `M3: map-foundation`

---

### M4 — Expanded Media View

Add split-screen view to `index.html`.

- Clicking a pin: map panel shrinks to left 33%; media panel appears at right 67%
- Close button (top right of media panel): return to full map
- **Photo display:** `<img>` using `display_src`; lazy loading
- **Video display:** `<video controls>` using `video_src`; inline playback
- **Metadata strip** below media: city, neighborhood, street, date, time_of_day, caption
  - Caption resolution: `author_caption ?? draft_caption ?? ""`
- **Navigation arrows:** left/right; cycle through all media at current pin
  - Active pin: pulse animation (CSS keyframe, scale 1→1.3→1)
  - Past last item: find nearest pin using Haversine distance formula on all entries in `data.json`; call `map.flyTo()` to animate; load first item at new pin
- **Responsive:** at viewport width < 768px, collapse to stacked (media top, mini-map 200px tall below)

Commit: `M4: expanded-view`

---

### M5 — Similar Media Row + Filter Panel

**Similar media row:**
- Appears at bottom of media panel in expanded view
- Constants at top of script (clearly labeled as tunable):
  ```js
  const SIMILAR_MATCH_THRESHOLD = 1; // min shared theme tags required
  const SIMILAR_MAX_RESULTS = 8;      // max thumbnails shown
  ```
- Query logic: from all `data.json` entries, find items where:
  1. Number of shared `theme_tags` with current item ≥ `SIMILAR_MATCH_THRESHOLD`
  2. At least one shared `scene_type` tag
  3. `city` is different from current item's city
- Sort by number of shared tags (descending); take top `SIMILAR_MAX_RESULTS`
- Render as horizontal scrollable row of 400px thumbnails; clicking navigates to that item

**Filter panel:**
- Slide-in drawer from left edge (CSS transform transition)
- Four sections of checkboxes: City / Media Type / Scene Type / Theme
- All options populated dynamically by scanning `data.json` on init — no hardcoded values
- "Clear all" button resets all filters
- Applying filters: hide pins whose entries don't match ALL active filters
- Serialize filter state to URL query params (`?city=Rotterdam&theme=bike+infrastructure`)
- On page load: parse URL params and restore filter state before rendering pins

Commit: `M5: similar-media-and-filters`

---

### M6 — Caption Admin Mode

**Constants at top of script:**
```js
const ADMIN_PASSWORD_HASH = "3e4d..."; // SHA-256 of "recon2026" — user should replace
```
Precompute SHA-256 of "recon2026" and hardcode it.

**Activation:**
- A small inconspicuous link/button in the footer: "Admin"
- Click opens a password modal
- On submit: SHA-256 hash the input (using Web Crypto API `crypto.subtle.digest`) and compare to `ADMIN_PASSWORD_HASH`
- Match: activate admin mode. No match: show "Incorrect password" error.

**Admin mode UI:**
- Edit icon (pencil) appears over every media item thumbnail on the map and in expanded view
- Clicking an item in admin mode opens an edit panel overlay:
  - Textarea for caption (pre-filled with current author_caption or draft_caption)
  - Tag chip display: each theme_tag as a removable chip; input to add new tags
  - "Save" (stores to in-memory diff) and "Cancel" buttons
- A floating action button appears (bottom right): "Download data.json (N edits)" where N is edit count badge
- Clicking it: deep-clone full `data.json` object, apply all diffs by `id`, trigger `<a download>` with JSON.stringify output

**No persistence:** admin state and diffs exist only in memory; page reload clears everything.

Commit: `M6: admin-mode`

---

### M7 — Narrative View

- On page load: `fetch('narrative.txt')` and store content in memory
- "Narrative" button in top nav: opens a centered overlay panel
- Panel: max-width 700px, centered, scrollable, with close button
- Auto-detect headings: scan text for lines that match any city name found in `data.json`, OR lines that are fully uppercase; render those as `<h2>` headings; all other lines as `<p>` paragraphs
- Handle missing `narrative.txt` gracefully: "Narrative coming soon." message; no error

Commit: `M7: narrative-view`

---

### M8 — Deployment Config + README

**`_headers` file** (Cloudflare Pages cache config):
```
/images/*
  Cache-Control: public, max-age=31536000, immutable

/video/*
  Cache-Control: public, max-age=31536000, immutable

/data.json
  Cache-Control: public, max-age=300
```

**README.md** must include:
1. Project description (2–3 sentences)
2. Prerequisites: Python 3.10+, ffmpeg, Node (optional for local preview)
3. First-time setup instructions (clone, venv, pip install, ffmpeg install)
4. How to run the processing script (including `--force` and `--file` flags)
5. How to get a Mapbox token and where to paste it
6. How to set `ANTHROPIC_API_KEY` in `.env`
7. How to preview locally
8. How to deploy to Cloudflare Pages (connect repo, set `main` branch)
9. How to use admin mode (activation, editing, downloading, redeploying)
10. What to do if videos appear in `large_videos.txt`

Final commit: `M8: deployment`

---

## QUALITY REQUIREMENTS

- No hardcoded city names, scene types, or theme tags anywhere in `index.html` — all derived from `data.json`
- `SIMILAR_MATCH_THRESHOLD`, `SIMILAR_MAX_RESULTS`, `MAPBOX_TOKEN`, `ADMIN_PASSWORD_HASH` must all be named constants at the top of the script block, with a comment explaining each
- Processing script must handle missing/malformed EXIF gracefully (log warning, continue)
- All console errors must be resolved before each milestone commit
- Test each milestone with a small sample dataset (5–10 files) before committing

---

## BLOCKING AMBIGUITIES — STOP AND ASK IF:
- A required API response format is different from what the spec describes
- A Mapbox GL JS behavior cannot be achieved as specified
- A file size or format constraint cannot be met with the specified tools

Otherwise: proceed with stated assumptions. Do not ask for confirmation on style choices, library versions, or minor implementation details — make a reasonable call and document it in a comment.
```
