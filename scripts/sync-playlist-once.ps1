param(
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$ConfigPath = Join-Path $Root 'site-config.json'
$LogPath = Join-Path $PSScriptRoot 'publish.log'

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $LogPath -Value $line
    Write-Host $line
}

Write-Log 'Syncing Spotify playlist...'
& (Join-Path $PSScriptRoot 'generate-spotify-tracks.ps1') -ConfigPath $ConfigPath

if ($LASTEXITCODE -eq 10 -or $Publish) {
    Write-Log 'Publishing site...'
    $trackCount = (Get-Content (Join-Path $Root 'spotify-tracks.json') -Raw | ConvertFrom-Json).count
    & (Join-Path $PSScriptRoot 'publish.ps1') -CommitMessage "Update Spotify playlist ($trackCount tracks)"
} elseif ($LASTEXITCODE -eq 0) {
    Write-Log 'Playlist unchanged.'
} else {
    throw "generate-spotify-tracks.ps1 failed with exit code $LASTEXITCODE"
}
