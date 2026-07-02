param(
    [string]$PlaylistId = '',
    [string]$OutPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'spotify-tracks.json'),
    [string]$ConfigPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'site-config.json')
)

$ErrorActionPreference = 'Stop'

if (-not $PlaylistId -and (Test-Path $ConfigPath)) {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $PlaylistId = $config.spotifyPlaylistId
}
if (-not $PlaylistId) {
    $PlaylistId = '4DaB0NVWfmH4KsyQo66xui'
}

$url = "https://open.spotify.com/embed/playlist/$PlaylistId"
$html = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

$matches = [regex]::Matches($html, '"uri":"(spotify:track:[^"]+)"')
$uris = @(
    foreach ($m in $matches) {
        $m.Groups[1].Value
    }
) | Select-Object -Unique

if (-not $uris.Count) {
    throw 'No tracks found in Spotify embed page.'
}

$tracks = @(
    foreach ($uri in $uris) {
        $id = $uri -replace '^spotify:track:', ''
        [ordered]@{
            id = $id
            uri = $uri
            url = "https://open.spotify.com/track/${id}?context=spotify:playlist:${PlaylistId}"
        }
    }
)

$newIds = ($tracks | ForEach-Object { $_.id }) -join '|'
$oldIds = ''
if (Test-Path $OutPath) {
    try {
        $old = Get-Content $OutPath -Raw | ConvertFrom-Json
        $oldIds = ($old.tracks | ForEach-Object { $_.id }) -join '|'
    } catch {
        $oldIds = ''
    }
}

$changed = $newIds -ne $oldIds

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    playlistId = $PlaylistId
    playlistUri = "spotify:playlist:$PlaylistId"
    count = $tracks.Count
    tracks = $tracks
}

$json = $manifest | ConvertTo-Json -Depth 5

if ($changed) {
    [System.IO.File]::WriteAllText($OutPath, $json, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Updated $($tracks.Count) tracks -> $OutPath"
} else {
    Write-Host "No playlist changes ($($tracks.Count) tracks)."
}

if ($changed) { exit 10 }
exit 0
