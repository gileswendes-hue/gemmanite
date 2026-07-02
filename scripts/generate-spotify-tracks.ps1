param(
    [string]$PlaylistId = '4DaB0NVWfmH4KsyQo66xui',
    [string]$OutPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'spotify-tracks.json')
)

$ErrorActionPreference = 'Stop'
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

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    playlistId = $PlaylistId
    playlistUri = "spotify:playlist:$PlaylistId"
    count = $tracks.Count
    tracks = $tracks
}

$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($OutPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $($tracks.Count) tracks -> $OutPath"
