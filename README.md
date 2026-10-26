# YuGangD · 鱼缸D

Windows 桌面动态壁纸：雨夜卧室循环场景 + 点击热区切换「躺床 / 工作」 + 半透明 DSH 浮窗。

三块屏画面镜像、只解码一次；壁纸挂在桌面最底层，不抢焦点、不进 Alt+Tab、不遮挡任何窗口。

---

## 功能

**壁纸**

- 雨夜卧室循环视频，她躺在床上玩手机
- 多显示器**镜像**显示：一个窗口横跨整个虚拟屏，页面里按屏幕切 pane，**只解码一次**
- 挂在 `WorkerW` 桌面层：不进 Alt+Tab、不抢焦点、任何窗口都能盖住它
- per-monitor DPI 感知，150% 缩放不会放大错位
- 按**工作区**铺画面，自动避开任务栏；任务栏显隐 2 秒内自动重排

**模式切换（热区）**

| 热区 | 动作 |
|---|---|
| 书桌上的笔记本 | 起身动画 → 工作模式（她坐电脑前打字循环） |
| 床 | 离开动画 → 回到壁纸模式 |
| 床头柜的书 | 打开设置窗口 |

- 热区是 SVG 轮廓，悬停时描边发光，跟着人物位置走
- 支持「跳过切换动画」：勾上后直接切模式，用 260ms 交叉溶解过渡，不闪黑
- 连点保护：900ms 内的重复点击直接丢弃，不会叠动画

**DSH 浮窗**

- 半透明玻璃质感，背后就是壁纸本身
- 跟随点击笔记本的那块屏幕弹出
- `Ctrl+D` 在主屏置顶；壁纸模式下再按一次收起，工作模式下再按一次只回桌面层
- 复用**主 DSH**（`127.0.0.1:331`），不另起进程；会话、历史、插件、小鲸鱼挂件全都在
- 小鲸鱼跟着浮窗走：浮窗出现她出现，浮窗隐藏她隐藏

---

## 应用

### 安装

在另一台电脑上打开 PowerShell，粘一句：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seasighly/yugang-d/main/install.ps1 | iex"
```

国内拉不动 raw 用镜像：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://cdn.jsdelivr.net/gh/seasighly/yugang-d@v1.3.7/install.ps1 | iex"
```

装完会在桌面和开始菜单各留一个 `YuGangD` 快捷方式。

### 热键

| 热键 | 作用 |
|---|---|
| `Ctrl + D` | 浮窗置顶 ⇄ 收回 |
| `Ctrl + Alt + Q` | 退出鱼缸D |
| `Ctrl + Alt + H` | 隐藏 / 显示壁纸 |

### 托盘菜单

右键托盘里的小图标：

- **隐藏任务栏** —— 连任务栏一起藏掉，画面自动铺满整屏
- **跳过切换动画** —— 直接切模式（带 260ms 交叉溶解）
- **重启浮层 DSH** —— 重新取一次 token 并刷新浮窗
- **重新加载 / 退出**

### 配置

```
%APPDATA%\鱼缸D\settings.ini
```

```ini
skip=0          ; 1 = 跳过切换动画
overlay=follow  ; 浮窗固定在点击的那块屏
```

### 卸载

删掉 `%LOCALAPPDATA%\YuGangD`，再删桌面和开始菜单两个快捷方式。

---

## 更新

**推荐方式：重新跑一遍安装命令**——脚本是幂等的，会先关掉正在运行的实例、覆盖安装、重建快捷方式。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seasighly/yugang-d/main/install.ps1 | iex"
```

只想手动换安装包：

```powershell
curl -L -o "%TEMP%\ygd.zip" https://github.com/seasighly/yugang-d/releases/latest/download/YGD-v1.3.7.zip
```

解压覆盖到 `%LOCALAPPDATA%\YuGangD`（覆盖前先退出鱼缸D）。

> 更新不会动 `%APPDATA%\鱼缸D\settings.ini`——配置在用户目录，不在安装目录里。

**只查更新不重装**（比对已装版本与最新 Release，落后才装）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seasighly/yugang-d/main/update.ps1 | iex"
```

输出示例：

```
  installed : 1.3.6
  latest    : 1.3.7
  Updating 1.3.6 -> 1.3.7 ...
```

已是最新时会直接打印 `Already up to date.` 并退出。

看改了什么：[CHANGELOG.md](CHANGELOG.md) ｜ [全部 Releases](https://github.com/seasighly/yugang-d/releases)

---

## 依赖

### 运行必需

| 依赖 | 说明 | 缺失时 |
|---|---|---|
| Windows 10 / 11 x64 | 用到 `WorkerW`、DWM、per-monitor DPI | 装不了 |
| **WebView2 Runtime** | Edge 内核，承载壁纸和浮窗 | 安装脚本自动装（winget → 官方引导包） |
| .NET Framework 4.8 | 程序是 WinForms，系统自带 | Win10 1809+ 自带 |

### 浮窗功能需要

| 依赖 | 说明 | 缺失时 |
|---|---|---|
| **DSH**（DeepSeek Harness） | 跑在 `127.0.0.1:331`，浮窗就是它的一个视口 | 安装脚本自动 `npm i -g @deepseek-ai/dsh` |
| **Node.js LTS** | DSH 的运行时 | 安装脚本自动装 |
| 本机 DeepSeek 凭据 | DSH 已登录的账号 / API Key | 浮窗里没内容，壁纸照常 |

> 没有 DSH 也能当**纯壁纸**用，只是浮窗是空的。

### 开发 / 构建用

| 工具 | 用途 |
|---|---|
| `csc.exe`（.NET Framework 自带） | 编译 C#，无需 VS / MSBuild |
| ffmpeg | 剪辑、烘焙无缝循环、抽帧 |
| potrace | 位图轮廓转 SVG 路径（开发期提取热区路径用） |
| Python + Pillow | 生成羽化遮罩、批量处理素材 |

---

## 致谢

- **[DeepSeek Harness](https://github.com/deepseek-ai)** —— 浮窗整个是它；会话、模型、插件都跑在 DSH 上
- **[dsh-whale-widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)** by **MeteorNOX** —— 右下角小鲸鱼挂件，代码 MIT。本项目没有内嵌，而是让 DSH 侧加载插件，浮窗里自然就有
- **Microsoft Edge WebView2** —— 三屏渲染和解码的实际执行者
- **ffmpeg / potrace / Pillow** —— 素材处理与热区提取的工具链
- **Wallpaper Engine 社区** —— 把窗口挂到 `WorkerW` 这套桌面层做法（`0x052C` 拆 `WorkerW`）的经典思路来源

---

## 项目结构

```
install.ps1        一键安装脚本（纯 ASCII，iex 安全）
install.cmd        双击入口
publish.ps1        一键发布：登录 → 建仓 → 推送 → 发 Release
CHANGELOG.md       更新日志
release/           发布用的 zip
src/               全部 C# 源码
  Program.cs       窗口、托盘、热键、桌面层挂载、分屏布局
  DshOverlay.cs    DSH 浮窗：视口、token、置顶切换
  MediaServer.cs   本地 HTTP：喂视频、代理 /dsh-whale/*
  DesktopHost.cs   WorkerW 挂载、任务栏显隐
  SettingsD.cs     设置窗口
  DpiAware.cs      per-monitor DPI
  DwmThumb.cs      DWM 缩略图实验（当前未启用）
```

## 编译

不需要 Visual Studio，用 .NET Framework 自带的编译器：

```powershell
csc /target:winexe /platform:x64 /out:鱼缸D.exe ^
    /r:Microsoft.Web.WebView2.Core.dll /r:Microsoft.Web.WebView2.WinForms.dll ^
    /r:System.Windows.Forms.dll /r:System.Drawing.dll src\*.cs
```

## 已知限制

- 浮窗和浏览器共用同一个 DSH 会话数据，**同一个对话不能两边同时打开**（DSH 的文件独占锁）
- 浮窗 token 从 `C:\鱼池\logs\dsh-331.log` 读取，路径写死在源码里，换机器要改
- 壁纸素材随包分发，仅用于运行本程序

## License

[MIT](LICENSE)
