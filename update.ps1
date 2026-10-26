# ============================================================
#  YuGangD updater  (pure ASCII, safe for: irm | iex)
#  Usage:
#    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm <RAW_URL>/update.ps1 | iex"
#  Compares the installed VERSION with the newest GitHub release tag and
#  re-runs the installer when a newer one exists.
# ============================================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$GitHubRepo = 'seasighly/yugang-d'
$RawBase    = "https://raw.githubusercontent.com/$GitHubRepo/main"
$InstallDir = Join-Path $env:LOCALAPPDATA 'YuGangD'
$VerFile    = Join-Path $InstallDir 'VERSION'

function Say($m, $c = 'Cyan') { Write-Host $m -ForegroundColor $c }

Say ""
Say "  YuGangD updater" DarkCyan
Say ""

# ---- installed version ----
$local = 'none'
if (Test-Path $VerFile) {
    try { $local = (Get-Content $VerFile -Raw).Trim() } catch { }
}
Say "  installed : $local"

# ---- latest version ----
$latest = $null
try {
    $api = "https://api.github.com/repos/$GitHubRepo/releases/latest"
    $rel = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 20 `
        -Headers @{ 'User-Agent' = 'YuGangD-updater'; 'Accept' = 'application/vnd.github+json' }
    $latest = $rel.tag_name -replace '^v', ''
} catch {
    Say "  could not reach GitHub: $($_.Exception.Message)" Yellow
    Say "  try again later, or rerun install.ps1" Yellow
    exit 1
}
Say "  latest    : $latest"

if ($local -eq $latest) {
    Say ""
    Say "  Already up to date." Green
    Say ""
    exit 0
}

Say ""
Say "  Updating $local -> $latest ..." Yellow
Say ""

# ---- run installer (idempotent: stops app, replaces files, rebuilds shortcuts) ----
$script = Invoke-WebRequest -Uri "$RawBase/install.ps1" -UseBasicParsing -TimeoutSec 30
Invoke-Expression $script.Content

Say ""
Say "  Update finished ($latest)." Green
Say ""
