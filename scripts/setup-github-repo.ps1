param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [string]$ConfigPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'site-config.json'),
    [switch]$Private
)

$ErrorActionPreference = 'Stop'
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$token = $env:GITHUB_TOKEN
if (-not $token) {
    throw @"
GITHUB_TOKEN is not set.

1. Open https://github.com/settings/tokens
2. Create a token with "repo" scope
3. In PowerShell run:
   `$env:GITHUB_TOKEN = 'your-token-here'
4. Run this script again, then publish.bat
"@
}

$owner = $config.githubOwner
$repo = $config.githubRepo
$headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

$body = @{
    name = $repo
    description = 'Gemma Rainbow World slideshow site'
    homepage = "https://$($config.domain)"
    private = [bool]$Private
    has_issues = $false
    has_projects = $false
    has_wiki = $false
    auto_init = $false
} | ConvertTo-Json

Write-Host "Creating GitHub repo $owner/$repo ..."
try {
    Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
    Write-Host 'Repository created.'
} catch {
    $detail = $_.ErrorDetails.Message
    if ($detail -match 'name already exists') {
        Write-Host 'Repository already exists; continuing.'
    } else {
        throw "Could not create repo: $detail"
    }
}

Write-Host @"

Next steps:
1. Open https://github.com/$owner/$repo/settings/pages
2. Set Source = Deploy from branch, branch = $($config.branch), folder = / (root)
3. Set Custom domain = $($config.domain)
4. Run E:\gemmanite\publish.bat

"@
