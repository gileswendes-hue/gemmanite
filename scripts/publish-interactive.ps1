$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$publish = Join-Path $PSScriptRoot 'publish.ps1'

Write-Host '=== Gemmanite publish ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $gh)) {
    Write-Host 'GitHub CLI not found. Install it, then run publish-now.bat again.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
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

if (-not (Test-GhLoggedIn -GhExe $gh)) {
    Write-Host 'You are not signed in to GitHub yet.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Run sign-in-to-github.bat first (code appears in that window).' -ForegroundColor Yellow
    Write-Host 'Or use sign-in-with-token.bat if that is easier.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit 1
}

& $publish
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Read-Host 'Press Enter to close'
