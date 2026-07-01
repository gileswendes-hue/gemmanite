$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$git = 'C:\Program Files\Git\cmd\git.exe'
$Root = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $Root 'site-config.json') -Raw | ConvertFrom-Json

Write-Host 'Paste your GitHub token (ghp_...) and press Enter:' -ForegroundColor Yellow
$token = Read-Host
if (-not $token) { throw 'No token provided.' }

$owner = $config.githubOwner
$repo = $config.githubRepo
$remoteUrl = "https://${owner}:${token}@github.com/${owner}/${repo}.git"

$headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}
$body = @{
    name = $repo
    description = 'Gemma Rainbow World slideshow site'
    homepage = "https://$($config.domain)"
    private = $false
} | ConvertTo-Json

Write-Host 'Creating GitHub repo (if needed)...' -ForegroundColor Cyan
try {
    Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
    Write-Host 'Repository created.' -ForegroundColor Green
} catch {
    if ($_.ErrorDetails.Message -match 'name already exists') {
        Write-Host 'Repository already exists.' -ForegroundColor Green
    } else {
        throw $_.ErrorDetails.Message
    }
}

& $git -C $Root remote set-url origin $remoteUrl
Write-Host 'Uploading photos to GitHub (this may take several minutes)...' -ForegroundColor Cyan
& $git -C $Root push -u origin $config.branch
Write-Host 'Upload complete.' -ForegroundColor Green
Write-Host 'Enable GitHub Pages: Settings -> Pages -> main branch -> / (root)' -ForegroundColor Yellow
Write-Host 'Set custom domain: gemmanite.co.uk' -ForegroundColor Yellow
