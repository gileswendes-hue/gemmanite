$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$token = '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'
$token | & $gh auth login --hostname github.com --git-protocol https --with-token
& $gh auth status
