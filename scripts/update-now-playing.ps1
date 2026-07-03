param(
    [string]$EnvFile = 'H:\secrets\gemmanite.env',
    [string]$OutPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'now-playing.json')
)

$ErrorActionPreference = 'Stop'

function Read-EnvMap([string]$Path) {
    $map = @{}
    if (-not (Test-Path $Path)) { return $map }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
        $pair = $_ -split '=', 2
        $map[$pair[0].Trim()] = $pair[1].Trim()
    }
    return $map
}

$cfg = Read-EnvMap $EnvFile
$clientId = $cfg['SPOTIFY_CLIENT_ID']
$clientSecret = $cfg['SPOTIFY_CLIENT_SECRET']
$refreshToken = $cfg['SPOTIFY_REFRESH_TOKEN']

if (-not $clientId -or -not $clientSecret -or -not $refreshToken) {
    throw "Missing Spotify credentials in $EnvFile"
}

$tokenBody = @{
    grant_type    = 'refresh_token'
    refresh_token = $refreshToken
}
$tokenAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${clientId}:${clientSecret}"))
$tokenRes = Invoke-RestMethod -Method Post -Uri 'https://accounts.spotify.com/api/token' `
    -Headers @{ Authorization = "Basic $tokenAuth" } `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body $tokenBody

$accessToken = $tokenRes.access_token
$headers = @{ Authorization = "Bearer $accessToken" }

try {
    $player = Invoke-WebRequest -Uri 'https://api.spotify.com/v1/me/player/currently-playing' `
        -Headers $headers -UseBasicParsing -ErrorAction Stop
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 204) {
        $player = $null
    } else {
        throw
    }
}

$payload = [ordered]@{
    ok        = $true
    playing   = $false
    track     = $null
    updatedAt = (Get-Date).ToUniversalTime().ToString('o')
}

if ($player -and $player.StatusCode -eq 200) {
    $data = $player.Content | ConvertFrom-Json
    if ($data.item) {
        $artists = @($data.item.artists | ForEach-Object { $_.name }) -join ', '
        $imageUrl = ''
        if ($data.item.album.images -and $data.item.album.images.Count -gt 0) {
            $imageUrl = $data.item.album.images[0].url
        }
        $payload.playing = ($data.is_playing -ne $false)
        $payload.track = [ordered]@{
            id         = $data.item.id
            name       = $data.item.name
            artist     = $artists
            album      = $data.item.album.name
            imageUrl   = $imageUrl
            url        = $data.item.external_urls.spotify
            progressMs = [int]$data.progress_ms
            durationMs = [int]$data.item.duration_ms
        }
    }
}

$json = $payload | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($OutPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Updated now playing -> $OutPath"
if ($payload.track) {
    Write-Host "Playing: $($payload.track.name) — $($payload.track.artist)"
} else {
    Write-Host 'Nothing playing right now.'
}

if ($payload.track) { exit 0 }
exit 0
