param(
    [switch]$Watch,
    [int]$WatchDelaySeconds = 30,
    [string]$CommitMessage = '',
    [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$ConfigPath = Join-Path $Root 'site-config.json'
$LogPath = Join-Path $PSScriptRoot 'publish.log'
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

function Get-GitExe {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "$env:ProgramFiles\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe"
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    throw 'Git not found. Install Git for Windows from https://git-scm.com/download/win'
}

$git = Get-GitExe

function Get-GhExe {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in @(
        "$env:ProgramFiles\GitHub CLI\gh.exe",
        "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe"
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}

$gh = Get-GhExe

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $LogPath -Value $line
    Write-Host $line
}

function Publish-Site {
    Write-Log 'Syncing Spotify playlist...'
    & (Join-Path $PSScriptRoot 'generate-spotify-tracks.ps1') -ConfigPath $ConfigPath

    Write-Log 'Generating photos manifest...'
    & (Join-Path $PSScriptRoot 'generate-photos-manifest.ps1') -Root $Root -ConfigPath $ConfigPath

    if (-not (Test-Path (Join-Path $Root '.git'))) {
        Write-Log 'Initialising git repository...'
        & $git -C $Root init -b $config.branch
    }

    $remoteName = 'origin'
    $remoteUrl = "https://github.com/$($config.githubOwner)/$($config.githubRepo).git"
    $remotes = & $git -C $Root remote
    if ($remotes -notcontains $remoteName) {
        Write-Log "Adding remote $remoteName -> $remoteUrl"
        & $git -C $Root remote add $remoteName $remoteUrl
    }

    & $git -C $Root add index.html photos.json spotify-tracks.json now-playing.json CNAME site-config.json .gitignore photos scripts README.md publish.bat watch-photos.bat publish-now.bat poll-playlist.bat sync-playlist.bat setup-spotify-auth.bat .github

    $status = & $git -C $Root status --porcelain
    if (-not $status) {
        Write-Log 'No changes to publish.'
        return
    }

    if (-not $CommitMessage) {
        $photoCount = (Get-Content (Join-Path $Root 'photos.json') -Raw | ConvertFrom-Json).count
        $trackCount = (Get-Content (Join-Path $Root 'spotify-tracks.json') -Raw | ConvertFrom-Json).count
        $trackChanged = $status -match 'spotify-tracks\.json'
        $photosChanged = $status -match '(^|\s)(photos/|photos\.json)'
        if ($trackChanged -and -not $photosChanged) {
            $CommitMessage = "Update Spotify playlist ($trackCount tracks)"
        } elseif ($trackChanged -and $photosChanged) {
            $CommitMessage = "Update photos ($photoCount) and Spotify playlist ($trackCount tracks)"
        } else {
            $CommitMessage = "Update site photos ($photoCount images)"
        }
    }

    $gitName = & $git -C $Root config user.name 2>$null
    $gitEmail = & $git -C $Root config user.email 2>$null
    if (-not $gitName -or -not $gitEmail) {
        & $git -C $Root config user.name 'Gemma Site'
        & $git -C $Root config user.email 'gemmanite@users.noreply.github.com'
    }

    Write-Log "Committing: $CommitMessage"
    & $git -C $Root commit -m $CommitMessage

    if ($SkipPush) {
        Write-Log 'SkipPush set; commit created locally only.'
        return
    }

    if ($gh) {
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $ghAuth = & $gh auth status 2>&1 | Out-String
        $ErrorActionPreference = $previous
        if ($ghAuth -notmatch 'Logged in to github.com') {
            Write-Log 'GitHub CLI is not signed in. Run publish-now.bat to sign in and upload.'
        } else {
            $repoSlug = "$($config.githubOwner)/$($config.githubRepo)"
            & $gh repo view $repoSlug 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Creating GitHub repo $repoSlug ..."
                & $gh repo create $repoSlug --public --description 'Gemma Rainbow World slideshow site' --source $Root --remote $remoteName --push
                if ($LASTEXITCODE -eq 0) {
                    Write-Log 'Repository created and pushed via GitHub CLI.'
                    return
                }
            }
        }
    }

    Write-Log 'Pushing to GitHub...'
    & $git -C $Root push -u $remoteName $config.branch
    if ($LASTEXITCODE -ne 0) {
        throw 'Git push failed. Sign in to GitHub (browser or PAT) and run publish.ps1 again.'
    }

    Write-Log 'Publish complete.'
}

if ($Watch) {
    Write-Log "Watching $($config.photosDir) for changes every $WatchDelaySeconds seconds..."
    $photosPath = Join-Path $Root $config.photosDir
    $watcher = New-Object System.IO.FileSystemWatcher $photosPath, '*.*'
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    $script:lastRun = [datetime]::MinValue

    $action = {
        $now = Get-Date
        if (($now - $script:lastRun).TotalSeconds -lt $using:WatchDelaySeconds) { return }
        $script:lastRun = $now
        try {
            Publish-Site
        } catch {
            Write-Log "Publish failed: $($_.Exception.Message)"
        }
    }

    Register-ObjectEvent $watcher Changed -Action $action | Out-Null
    Register-ObjectEvent $watcher Created -Action $action | Out-Null
    Register-ObjectEvent $watcher Deleted -Action $action | Out-Null
    Register-ObjectEvent $watcher Renamed -Action $action | Out-Null

    Publish-Site

    Write-Host 'Watcher running. Press Enter to stop.'
    Read-Host | Out-Null
} else {
    Publish-Site
}
