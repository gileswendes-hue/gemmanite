$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'

if (-not (Test-Path $gh)) {
    Write-Host 'GitHub CLI not found.' -ForegroundColor Red
    exit 1
}

function Test-GhLoggedIn {
    param([string]$GhExe)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $GhExe auth status 2>&1 | Out-String
    $ErrorActionPreference = $previous
    return ($output -match 'Logged in to github.com')
}

if (Test-GhLoggedIn -GhExe $gh) {
    Write-Host ''
    Write-Host 'Already signed in to GitHub.' -ForegroundColor Green
    & $gh auth status
    Write-Host ''
    Write-Host 'Run publish-now.bat to upload photos.' -ForegroundColor Cyan
    exit 0
}

Write-Host ''
Write-Host 'Starting GitHub sign-in...' -ForegroundColor Yellow
Write-Host ''
Write-Host '>>> WATCH THIS WINDOW for a code like:  XXXX-XXXX' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host '>>> Then go to:  https://github.com/login/device' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ''
Write-Host 'When asked, choose:' -ForegroundColor Gray
Write-Host '  - GitHub.com'
Write-Host '  - HTTPS'
Write-Host '  - Login with a web browser'
Write-Host ''

# Device-code flow (no 127.0.0.1 callback). Code is printed in this window.
& $gh auth login --hostname github.com --git-protocol https

Write-Host ''
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Sign-in successful!' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next: double-click publish-now.bat to upload your photos.' -ForegroundColor Cyan
} else {
    Write-Host 'Sign-in did not complete.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Alternative: use a Personal Access Token instead.' -ForegroundColor Yellow
    Write-Host '1. Open https://github.com/settings/tokens/new'
    Write-Host '2. Note = Gemmanite, tick "repo", click Generate token'
    Write-Host '3. Copy the token (starts with ghp_)'
    Write-Host '4. Run sign-in-with-token.bat and paste it'
}
