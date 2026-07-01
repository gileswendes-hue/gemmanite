$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'

if (-not (Test-Path $gh)) {
    Write-Host 'GitHub CLI not found.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Paste your GitHub token (ghp_...) and press Enter:' -ForegroundColor Yellow
Write-Host '(nothing will show as you type — that is normal)' -ForegroundColor Gray
$token = Read-Host -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if (-not $plain -or $plain.Length -lt 20) {
    Write-Host 'Token too short or empty.' -ForegroundColor Red
    exit 1
}

$plain | & $gh auth login --hostname github.com --git-protocol https --with-token

if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host 'Signed in successfully!' -ForegroundColor Green
    Write-Host 'Now run publish-now.bat to upload photos.' -ForegroundColor Cyan
} else {
    Write-Host 'Sign-in failed. Check the token has "repo" scope.' -ForegroundColor Red
}
