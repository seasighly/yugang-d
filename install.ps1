# ============================================================
#  鱼缸D 一键安装脚本
#  用法（一行命令）：
#    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/<OWNER>/<REPO>/main/install.ps1 | iex"
#  它会：检查并补齐 WebView2 / Node.js / DSH，然后下载安装鱼缸D 并创建快捷方式
# ============================================================

# 可用环境变量 YGD_LOCALZIP 指定本地安装包（离线/测试用），留空则从 GitHub 下载
$LocalZip = $env:YGD_LOCALZIP

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# 仓库地址（发布时自动替换）
$GitHubRepo = 'seasighly/yugang-d'
$AssetName  = 'YGD-v1.3.4.zip'
$Version    = '1.3.4'
$InstallDir = Join-Path $env:LOCALAPPDATA '鱼缸D'

function Say($msg, $color = 'Cyan') { Write-Host $msg -ForegroundColor $color }
function Ok($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [注意] $msg" -ForegroundColor Yellow }
function Bad($msg)  { Write-Host "  [缺失] $msg" -ForegroundColor Red }

Say ""
Say "  ============================================" DarkCyan
Say "     鱼缸D  $Version  一键安装" DarkCyan
Say "  ============================================" DarkCyan
Say ""

# ---------- 0. 基本环境 ----------
Say "[0/4] 检查系统环境"

if ([Environment]::OSVersion.Version.Major -lt 10) {
    Bad "需要 Windows 10 或更高版本"
    exit 1
}
Ok "系统版本 $([Environment]::OSVersion.Version.ToString(3))"

$is64 = [Environment]::Is64BitOperatingSystem
if (-not $is64) { Bad "需要 64 位系统"; exit 1 }
Ok "64 位系统"

try {
    $null = Get-Command powershell.exe -ErrorAction Stop
    Ok "PowerShell 可用"
} catch { Bad "PowerShell 不可用"; exit 1 }

# ---------- 1. WebView2 运行时 ----------
Say ""
Say "[1/4] 检查 WebView2 运行时"

$wv2Keys = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
$wv2Ver = $null
foreach ($k in $wv2Keys) {
    try {
        $v = (Get-ItemProperty -Path $k -ErrorAction Stop).pv
        if ($v) { $wv2Ver = $v; break }
    } catch { }
}

if ($wv2Ver) {
    Ok "已安装 WebView2 运行时 $wv2Ver"
} else {
    Warn "未检测到 WebView2 运行时，正在自动安装（鱼缸D 必需）"
    $installed = $false

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            Say "  使用 winget 安装 Microsoft.EdgeWebView2Runtime ..." Gray
            winget install --id Microsoft.EdgeWebView2Runtime -e --silent `
                --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Null
            $installed = $true
        } catch {
            Warn "winget 安装失败：$($_.Exception.Message)"
        }
    }

    if (-not $installed) {
        try {
            Say "  下载官方引导安装程序 ..." Gray
            $boot = Join-Path $env:TEMP 'MicrosoftEdgeWebview2Setup.exe'
            Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $boot -UseBasicParsing
            Start-Process -FilePath $boot -ArgumentList '/silent', '/install' -Wait
            $installed = $true
        } catch {
            Warn "下载安装失败：$($_.Exception.Message)"
        }
    }

    if ($installed) { Ok "WebView2 运行时安装完成" }
    else { Bad "WebView2 安装失败，请手动安装：https://developer.microsoft.com/microsoft-edge/webview2/" }
}

# ---------- 2. DSH（浮窗需要） ----------
Say ""
Say "[2/4] 检查 DSH（浮窗需要，可跳过）"

$dshReady = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $async = $tcp.BeginConnect('127.0.0.1', 331, $null, $null)
    if ($async.AsyncWaitHandle.WaitOne(800)) { $tcp.EndConnect($async); $dshReady = $true }
    $tcp.Close()
} catch { }

if ($dshReady) {
    Ok "DSH 已在 127.0.0.1:331 运行，浮窗可直接使用"
} else {
    Warn "331 端口没有 DSH 在跑，壁纸能用，但浮窗会空着"

    $hasNode = Get-Command node -ErrorAction SilentlyContinue
    $hasNpm  = Get-Command npm  -ErrorAction SilentlyContinue

    if (-not $hasNode -or -not $hasNpm) {
        Warn "未检测到 Node.js，正在安装（DSH 依赖它）"
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try {
                winget install --id OpenJS.NodeJS.LTS -e --silent `
                    --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Null
                $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                            [Environment]::GetEnvironmentVariable('Path', 'User')
                Ok "Node.js 安装完成"
            } catch { Warn "Node.js 安装失败：$($_.Exception.Message)" }
        } else {
            Warn "没有 winget，请手动安装 Node.js：https://nodejs.org/"
        }
    } else {
        Ok "Node.js 已安装 $((node --version))"
    }

    if ((Get-Command npm -ErrorAction SilentlyContinue) -and -not (Get-Command dsh -ErrorAction SilentlyContinue)) {
        Warn "未检测到 dsh 命令，正在安装 @deepseek-ai/dsh（可能要几分钟）"
        try {
            npm install -g @deepseek-ai/dsh 2>&1 | Out-Null
            Ok "DSH 安装完成"
        } catch { Warn "DSH 安装失败：$($_.Exception.Message)" }
    }

    Say "  启动 DSH 后浮窗才有内容：dsh web --profile web --port 331" Gray
}

# ---------- 3. 下载鱼缸D ----------
Say ""
Say "[3/4] 下载并安装 鱼缸D"

$zipPath = Join-Path $env:TEMP 'YGD-latest.zip'
$url = "https://github.com/$GitHubRepo/releases/latest/download/$AssetName"

if ($LocalZip) {
    if (-not (Test-Path $LocalZip)) { Bad "本地安装包不存在：$LocalZip"; exit 1 }
    Copy-Item $LocalZip $zipPath -Force
    Ok "使用本地安装包 $LocalZip"
} else {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Say "  下载 $url" Gray
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Ok "下载完成 $([math]::Round((Get-Item $zipPath).Length / 1MB, 2)) MB"
    } catch {
        Bad "下载失败：$($_.Exception.Message)"
        Say "  请检查网络，或手动从 GitHub Releases 下载" Gray
        exit 1
    }
}

if (Test-Path $InstallDir) {
    $running = Get-Process '鱼缸D' -ErrorAction SilentlyContinue
    if ($running) { $running | Stop-Process -Force; Start-Sleep -Milliseconds 800 }
    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

$exe = Join-Path $InstallDir '鱼缸D.exe'
if (-not (Test-Path $exe)) { Bad "安装包内容异常，没找到 鱼缸D.exe"; exit 1 }
Ok "安装到 $InstallDir"

# ---------- 4. 快捷方式 ----------
Say ""
Say "[4/4] 创建快捷方式"

$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop '鱼缸D.lnk'
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = $exe
$sc.WorkingDirectory = $InstallDir
$sc.IconLocation = $exe
$sc.Description = '鱼缸D 动态壁纸'
$sc.Save()
Ok "桌面快捷方式已创建"

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$lnk2 = Join-Path $startMenu '鱼缸D.lnk'
$sc2 = $ws.CreateShortcut($lnk2)
$sc2.TargetPath = $exe
$sc2.WorkingDirectory = $InstallDir
$sc2.IconLocation = $exe
$sc2.Save()
Ok "开始菜单快捷方式已创建"

# ---------- 启动 ----------
Say ""
Say "  安装完成，正在启动 ..." Green
Start-Process -FilePath $exe -WorkingDirectory $InstallDir
Start-Sleep -Seconds 2

Say ""
Say "  ============================================" DarkCyan
Say "   已就绪" DarkCyan
Say "   热键：Ctrl+D 浮窗置顶 / Ctrl+Alt+Q 退出" DarkCyan
Say "   托盘图标：右键可隐藏任务栏、跳过动画、重标热区" DarkCyan
Say "  ============================================" DarkCyan
Say ""
