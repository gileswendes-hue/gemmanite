# Gemmanite site publisher

Static slideshow site for **gemmanite.co.uk**, hosted on GitHub Pages.

## Folder layout

```
E:\gemmanite\
  photos\          <- drop new photos here (885 images, ~427 MB)
  index.html       <- slideshow page
  photos.json      <- auto-generated manifest
  CNAME            <- gemmanite.co.uk
  site-config.json <- GitHub owner/repo settings
  publish.bat      <- upload everything to GitHub
  watch-photos.bat <- auto-upload when photos change
```

## One-time GitHub setup

1. Edit `site-config.json` if your GitHub username is not `gileswendes`.
2. Create the repo (pick one):
   - **GitHub website:** create a new public repo named `gemmanite.co.uk` (empty, no README).
   - **Or with a token:**
     ```powershell
     $env:GITHUB_TOKEN = 'ghp_...'
     powershell -ExecutionPolicy Bypass -File E:\gemmanite\scripts\setup-github-repo.ps1
     ```
3. Enable Pages: repo **Settings → Pages → Deploy from branch → main → / (root)**.
4. Set custom domain to `gemmanite.co.uk` on the same page.

## Publish photos

Double-click **`publish.bat`**, or:

```powershell
powershell -ExecutionPolicy Bypass -File E:\gemmanite\scripts\publish.ps1
```

This will:
- scan `E:\gemmanite\photos`
- regenerate `photos.json`
- commit any changes
- push to GitHub

First push uploads all ~885 photos (~427 MB) and may take several minutes.

## Auto-upload new photos

Run **`watch-photos.bat`** — it republishes whenever you add, change, or remove files in `photos\`.

## Local preview

```powershell
cd E:\gemmanite
python -m http.server 8080
```

Then open http://localhost:8080 (Spotify controls need HTTPS/hosting to work fully).
