param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [string]$ConfigPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'site-config.json')
)

$ErrorActionPreference = 'Stop'
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$photosDir = Join-Path $Root $config.photosDir
$manifestPath = Join-Path $Root 'photos.json'

if (-not (Test-Path $photosDir)) {
    throw "Photos folder not found: $photosDir"
}

$extensions = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.bmp')
$files = Get-ChildItem -Path $photosDir -File |
    Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object LastWriteTime, Name

$photos = @(
    foreach ($file in $files) {
        $relative = ($config.photosDir.TrimEnd('/') + '/' + $file.Name) -replace '\\', '/'
        [ordered]@{
            path = $relative
            name = $file.Name
            modified = $file.LastWriteTimeUtc.ToString('o')
            bytes = $file.Length
        }
    }
)

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    count = $photos.Count
    intervalSeconds = [int]$config.slideIntervalSeconds
    photos = @($photos | ForEach-Object { $_.path })
}

$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Generated photos.json with $($photos.Count) photos -> $manifestPath"
