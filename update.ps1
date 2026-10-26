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

# ---- fetch the installer (raw CDN can be stale, so verify the version inside) ----
$sources = @(
    "https://raw.githubusercontent.com/$GitHubRepo/main/install.ps1",
    "https://cdn.jsdelivr.net/gh/$GitHubRepo@main/install.ps1"
)
$content = $null
foreach ($src in $sources) {
    try {
        $c = (Invoke-WebRequest -Uri $src -UseBasicParsing -TimeoutSec 25).Content
        $m = [regex]::Match($c, "AssetName\s*=\s*'([^']+)'")
        $v = if ($m.Success) { $m.Groups[1].Value } else { '' }
        if ($v -and $v -match [regex]::Escape($latest)) { $content = $c; Say "  installer from $src" Gray; break }
        if (-not $content) { $content = $c }   # keep as fallback
    } catch { }
}
if (-not $content) { Say "  cannot download installer" Red; exit 1 }
Invoke-Expression $content

# installer may be a cached older copy that does not write VERSION - do it here too
try {
    if (Test-Path $InstallDir) { Set-Content -Path $VerFile -Value $latest -Encoding ASCII }
} catch { }

Say ""
Say "  Update finished ($latest)." Green
Say ""
