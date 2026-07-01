$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$publish = Join-Path $PSScriptRoot 'publish.ps1'

Write-Host '=== Gemmanite publish ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $gh)) {
    Write-Host 'GitHub CLI not found. Install it, then run publish.bat again.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

$auth = & $gh auth status 2>&1 | Out-String
if ($auth -notmatch 'Logged in to github.com') {
    Write-Host 'Sign in to GitHub in the browser window that opens...' -ForegroundColor Yellow
    & $gh auth login --hostname github.com --git-protocol https --web
}

& $publish
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Read-Host 'Press Enter to close'
