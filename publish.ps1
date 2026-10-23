# ============================================================
#  一键发布到 GitHub
#  用法：  .\publish.ps1 -RepoName yugang-d [-Private]
#  做的事：登录 → 建仓 → 提交 → 推送上云 → 发 Release（带安装包）→ 打印一行安装命令
# ============================================================
param(
    [string]$RepoName = 'yugang-d',
    [switch]$Private
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Say($m, $c = 'Cyan') { Write-Host $m -ForegroundColor $c }

Say ""
Say "  ================  鱼缸D 发布  ================" DarkCyan
Say ""

# ---------- 0. 工具 ----------
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Say "缺少 gh（GitHub CLI）" Red; exit 1 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Say "缺少 git" Red; exit 1 }

# ---------- 1. 登录 ----------
Say "[1/6] 检查 GitHub 登录状态"
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Say "  未登录，开始网页登录（会给你一个 8 位码，在浏览器里输入）" Yellow
    gh auth login --hostname github.com --git-protocol https --web
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Say "  登录失败" Red; exit 1 }
}
$owner = (gh api user --jq .login).Trim()
Say "  已登录：$owner" Green

$full = "$owner/$RepoName"

# ---------- 2. 替换占位符 ----------
Say ""
Say "[2/6] 写入仓库地址 $full"
$ver = (Get-Content "$root\VERSION" -Raw).Trim()
$inst = Get-Content "$root\install.ps1" -Raw
$inst = $inst -replace "OWNER/REPO", $full
[System.IO.File]::WriteAllText("$root\install.ps1", $inst, (New-Object System.Text.UTF8Encoding($true)))

$readme = Get-Content "$root\README.md" -Raw
$readme = $readme -replace "OWNER/REPO", $full
[System.IO.File]::WriteAllText("$root\README.md", $readme, (New-Object System.Text.UTF8Encoding($false)))

# ---------- 3. git 初始化 ----------
Say ""
Say "[3/6] 初始化仓库并提交"
if (-not (Test-Path "$root\.git")) {
    git init | Out-Null
    git branch -M main
}
git config user.name  "$owner" 2>$null
git config user.email "$owner@users.noreply.github.com" 2>$null
git add -A
git commit -m "鱼缸D v$ver" 2>&1 | Out-Null

# ---------- 4. 建仓并推送 ----------
Say ""
Say "[4/6] 创建远程仓库并推送"
$exists = gh repo view $full 2>&1
if ($LASTEXITCODE -ne 0) {
    $vis = if ($Private) { '--private' } else { '--public' }
    gh repo create $RepoName $vis --source . --remote origin --push --description "鱼缸D — Windows 三屏动态壁纸 + DSH 浮窗"
} else {
    Say "  仓库已存在，直接推送" Gray
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$full.git"
    git push -u origin main --force
}

# ---------- 5. 发 Release ----------
Say ""
Say "[5/6] 创建 Release 并上传安装包"
$asset = "$root\release\YGD-v$ver.zip"
if (-not (Test-Path $asset)) { Say "  找不到 $asset" Red; exit 1 }

gh release view "v$ver" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    gh release upload "v$ver" $asset --clobber
} else {
    gh release create "v$ver" $asset --title "鱼缸D v$ver" --notes "自动发布：三屏镜像壁纸 + 半透明 DSH 浮窗"
}

# ---------- 6. 一行安装命令 ----------
Say ""
Say "[6/6] 完成" Green
Say ""
Say "  别的电脑上，一条命令装好：" Yellow
Say ""
Say "  powershell -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/$full/main/install.ps1 | iex`"" White
Say ""
Say "  仓库地址：https://github.com/$full" Cyan
Say ""
