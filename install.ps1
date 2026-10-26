# ============================================================
#  YuGangD one-line installer  (pure ASCII, safe for: irm | iex)
#  Usage:
#    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm <RAW_URL>/install.ps1 | iex"
#  It checks/installs WebView2 Runtime, Node.js and DSH, then downloads
#  YuGangD, installs it to %LOCALAPPDATA%\YuGangD, makes shortcuts, launches.
# ============================================================

# Optional: set YGD_LOCALZIP to a local zip path for offline install
$LocalZip = $env:YGD_LOCALZIP

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$GitHubRepo = 'seasighly/yugang-d'
$AssetName  = 'YGD-v1.3.6.zip'
$Version    = '1.3.6'
$AppName    = 'YuGangD'
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName

function Say($m, $c = 'Cyan') { Write-Host $m -ForegroundColor $c }
function Ok($m)   { Write-Host "  [OK]      $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN]    $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  [MISSING] $m" -ForegroundColor Red }

Say ""
Say "  ==============================================="  DarkCyan
Say "     YuGangD  v$Version  installer"               DarkCyan
Say "  ==============================================="  DarkCyan
Say ""

# ---------- 0. basic env ----------
Say "[0/4] Checking system"
if ([Environment]::OSVersion.Version.Major -lt 10) { Bad "Windows 10 or newer required"; exit 1 }
Ok "Windows $([Environment]::OSVersion.Version.ToString(3))"
if (-not [Environment]::Is64BitOperatingSystem) { Bad "64-bit Windows required"; exit 1 }
Ok "64-bit OS"
Ok "PowerShell ready"

# ---------- 1. WebView2 ----------
Say ""
Say "[1/4] Checking WebView2 Runtime"
$wv2Keys = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
$wv2Ver = $null
foreach ($k in $wv2Keys) {
    try { $v = (Get-ItemProperty -Path $k -ErrorAction Stop).pv; if ($v) { $wv2Ver = $v; break } } catch { }
}
if ($wv2Ver) {
    Ok "WebView2 Runtime $wv2Ver"
} else {
    Warn "WebView2 Runtime not found, installing ..."
    $okInstall = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install --id Microsoft.EdgeWebView2Runtime -e --silent `
                --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Null
            $okInstall = $true
        } catch { Warn "winget failed: $($_.Exception.Message)" }
    }
    if (-not $okInstall) {
        try {
            $boot = Join-Path $env:TEMP 'MicrosoftEdgeWebview2Setup.exe'
            Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $boot -UseBasicParsing
            Start-Process -FilePath $boot -ArgumentList '/silent','/install' -Wait
            $okInstall = $true
        } catch { Warn "download failed: $($_.Exception.Message)" }
    }
    if ($okInstall) { Ok "WebView2 installed" }
    else { Bad "WebView2 install failed - see https://developer.microsoft.com/microsoft-edge/webview2/" }
}

# ---------- 2. DSH (optional, powers the floating panel) ----------
Say ""
Say "[2/4] Checking DSH (needed by the floating panel)"
$dshReady = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $async = $tcp.BeginConnect('127.0.0.1', 331, $null, $null)
    if ($async.AsyncWaitHandle.WaitOne(800)) { $tcp.EndConnect($async); $dshReady = $true }
    $tcp.Close()
} catch { }

if ($dshReady) {
    Ok "DSH is running on 127.0.0.1:331"
} else {
    Warn "No DSH on port 331 - wallpaper works, floating panel will be empty"
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Warn "Node.js not found, installing ..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try {
                winget install --id OpenJS.NodeJS.LTS -e --silent `
                    --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Null
                $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                            [Environment]::GetEnvironmentVariable('Path','User')
                Ok "Node.js installed"
            } catch { Warn "Node.js install failed: $($_.Exception.Message)" }
        } else { Warn "No winget - install Node.js manually: https://nodejs.org/" }
    } else { Ok "Node.js $((node --version))" }

    if ((Get-Command npm -ErrorAction SilentlyContinue) -and -not (Get-Command dsh -ErrorAction SilentlyContinue)) {
        Warn "Installing @deepseek-ai/dsh (may take a few minutes) ..."
        try { npm install -g @deepseek-ai/dsh 2>&1 | Out-Null; Ok "DSH installed" }
        catch { Warn "DSH install failed: $($_.Exception.Message)" }
    }
    Say "  Start it later with:  dsh web --profile web --port 331"  Gray
}

# ---------- 3. download & install ----------
Say ""
Say "[3/4] Downloading $AppName"
$zipPath = Join-Path $env:TEMP 'YuGangD-latest.zip'
$url = "https://github.com/$GitHubRepo/releases/latest/download/$AssetName"

if ($LocalZip) {
    if (-not (Test-Path $LocalZip)) { Bad "local zip not found: $LocalZip"; exit 1 }
    Copy-Item $LocalZip $zipPath -Force
    Ok "using local zip"
} else {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Say "  $url" Gray
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Ok "downloaded $([math]::Round((Get-Item $zipPath).Length / 1MB, 2)) MB"
    } catch {
        Bad "download failed: $($_.Exception.Message)"
        exit 1
    }
}

# stop a running instance (match by install path, exe name is non-ASCII)
try {
    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -and $_.Path.StartsWith($InstallDir, [StringComparison]::OrdinalIgnoreCase) } catch { $false }
    } | ForEach-Object { try { $_.Kill(); } catch { } }
    Start-Sleep -Milliseconds 900
} catch { }
if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

$exe = Get-ChildItem $InstallDir -Filter '*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) { Bad "no exe found in the package"; exit 1 }
$exePath = $exe.FullName
Ok "installed to $InstallDir"
Ok "executable: $($exe.Name)"

# ---------- 4. shortcuts ----------
Say ""
Say "[4/4] Creating shortcuts"
$ws = New-Object -ComObject WScript.Shell
$targets = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'YuGangD.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\YuGangD.lnk')
)
foreach ($lnk in $targets) {
    try {
        $sc = $ws.CreateShortcut($lnk)
        $sc.TargetPath = $exePath
        $sc.WorkingDirectory = $InstallDir
        $sc.IconLocation = $exePath
        $sc.Description = 'YuGangD dynamic wallpaper'
        $sc.Save()
        Ok "shortcut: $lnk"
    } catch { Warn "shortcut failed: $lnk" }
}

# ---------- launch ----------
Say ""
Say "  Done. Starting ..." Green
Start-Process -FilePath $exePath -WorkingDirectory $InstallDir
Start-Sleep -Seconds 2

Say ""
Say "  ==============================================="  DarkCyan
Say "   Ready"                                          DarkCyan
Say "   Hotkeys: Ctrl+D panel on top / Ctrl+Alt+Q quit" DarkCyan
Say "   Tray: hide taskbar, skip animation, re-calibrate" DarkCyan
Say "  ==============================================="  DarkCyan
Say ""
