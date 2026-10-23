# 鱼缸D v1.3.4

Windows 桌面动态壁纸：三屏镜像的雨夜卧室场景 + 点击热区切换工作/躺床模式 + 半透明 DSH 浮窗。

## 一条命令安装

在**别的电脑**上打开 PowerShell（或 CMD 里调 powershell），粘贴：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seasighly/yugang-d/main/install.ps1 | iex"
```

脚本会自动：

1. 检查 Windows 版本 / 64 位
2. 检查 **WebView2 运行时**，缺了自动装
3. 检查 **Node.js / DSH**，缺了自动装（浮窗需要）
4. 下载最新安装包，装到 `%LOCALAPPDATA%\鱼缸D`
5. 创建桌面和开始菜单快捷方式并启动

卸载：删掉 `%LOCALAPPDATA%\鱼缸D` 和两个快捷方式即可。

---
## 运行环境

| 项 | 要求 |
|---|---|
| 系统 | Windows 10 / 11（x64） |
| 运行时 | **WebView2 Runtime**（Win11 自带；Win10 如缺，装 [Evergreen Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)） |
| DSH | 主 DSH 需运行在 **127.0.0.1:331**（浮窗复用它，不再单独起一份） |

## 启动

双击 `鱼缸D.exe`。

想开机自启：`Win+R` → 输入 `shell:startup` → 把 `鱼缸D.exe` 的快捷方式拖进去。

## 怎么用

**壁纸模式（默认）**
- 画面：她躺在床上玩手机
- 点**书桌上的笔记本** → 播起身动画 → 进入工作模式 + 弹出 DSH 浮窗
- 点**床头柜的书** → 打开设置

**工作模式**
- 画面：她坐在电脑前打字（循环）
- 点**床** → 播离开动画 → 回到壁纸模式，浮窗收起

## 热键

| 热键 | 作用 |
|---|---|
| `Ctrl + D` | 浮窗置顶显示 ⇄ 收回（壁纸模式下来回一次就收起；工作模式下来回一次只回桌面层） |
| `Ctrl + Alt + Q` | 退出鱼缸D |
| `Ctrl + Alt + H` | 隐藏/显示壁纸窗口 |

## 托盘菜单（右键小图标）

- **隐藏任务栏**：连任务栏一起藏掉（画面会自动铺满整屏）
- **跳过切换动画**：直接切换两个模式，不播起身/离开动画（会做 260ms 交叉溶解）
- **标定模式**：重新标定热区（在画面上点边界点，回车提交）
- **重启浮层 DSH**：让浮窗重新拿一次 token 并刷新页面
- **重新加载 / 退出**

## 配置文件

```
%APPDATA%\鱼缸D\settings.ini
```

```ini
skip=0          ; 1 = 跳过切换动画
overlay=follow  ; 浮窗固定在点击的那块屏
```

## 文件结构

```
鱼缸D.exe                     主程序
Microsoft.Web.WebView2.*.dll  WebView2 托管程序集
WebView2Loader.dll            WebView2 加载器（必须和 exe 同目录）
web/
  index.html                  壁纸页面（三屏分画面 + 热区）
  assets/
    bed.mp4                   躺床循环
    desk.mp4                  工作循环（首尾已烘焙无缝）
    rise.mp4                  起身动画
    leave.mp4                 离开动画
src/                          源码（C#，用 csc 直接编译）
```

## 实现要点

- **三屏镜像**：一个 WebView2 窗口横跨整个虚拟屏，页面里按屏幕切三块 pane，各放一份视频——只解码一次
- **桌面层**：窗口挂到 `WorkerW` 下（`SetParent`），因此不进 Alt+Tab、不遮挡任何窗口
- **DPI**：启动时开启 per-monitor DPI 感知，否则窗口会比实际屏幕大 1.5 倍
- **避开任务栏**：分屏区域用 `WorkingArea`，任务栏显隐会在 2 秒内自动重排
- **浮窗**：独立 WebView2 窗口，载入 `http://127.0.0.1:331/?token=...`（token 从 `C:\鱼池\logs\dsh-331.log` 读取）

## 已知限制

- 浮窗和浏览器共用同一个 DSH 会话数据，**同一个对话不能两边同时打开**（DSH 的文件独占锁）
- token 日志路径固定为 `C:\鱼池\logs\dsh-331.log`，换机器需要改源码里的 `DshOverlay.LogPath`
- 小鲸鱼挂件由 DSH 331 的 `dsh-whale-widget` 插件提供，浮窗里才出现，壁纸层没有
