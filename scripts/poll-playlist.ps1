param(
    [int]$IntervalMinutes = 0
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$ConfigPath = Join-Path $Root 'site-config.json'
$LogPath = Join-Path $PSScriptRoot 'publish.log'
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

if ($IntervalMinutes -le 0) {
    $IntervalMinutes = [int]$config.playlistPollMinutes
    if ($IntervalMinutes -le 0) { $IntervalMinutes = 15 }
}

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $LogPath -Value $line
    Write-Host $line
}

function Sync-Playlist {
    Write-Log 'Polling Spotify playlist...'
    & (Join-Path $PSScriptRoot 'generate-spotify-tracks.ps1') -ConfigPath $ConfigPath
    if ($LASTEXITCODE -eq 10) {
        Write-Log 'Playlist changed — publishing...'
        $trackCount = (Get-Content (Join-Path $Root 'spotify-tracks.json') -Raw | ConvertFrom-Json).count
        & (Join-Path $PSScriptRoot 'publish.ps1') -CommitMessage "Update Spotify playlist ($trackCount tracks)"
    } else {
        Write-Log 'Playlist unchanged.'
    }
}

Write-Log "Playlist poller started (every $IntervalMinutes minutes)."
Sync-Playlist

while ($true) {
    Start-Sleep -Seconds ($IntervalMinutes * 60)
    Sync-Playlist
}
