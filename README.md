# YuGangD · 鱼缸D

Windows 三屏镜像动态壁纸 + 半透明 DSH 浮窗。

- 桌面层播放雨夜卧室循环视频（挂 WorkerW，不进 Alt+Tab，不遮挡任何窗口）
- 点书桌笔记本 → 起身动画 → 工作模式 + 弹出半透明 DSH 浮窗
- 点床 → 离开动画 → 回到壁纸模式
- 三块屏画面镜像，只解码一次
- 浮窗跟随点击的屏幕；`Ctrl+D` 在主屏置顶

---

## 一条命令安装

在**另一台电脑**上打开 PowerShell，粘贴：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seasighly/yugang-d/main/install.ps1 | iex"
```

国内网络拉不动 raw 时用镜像：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://cdn.jsdelivr.net/gh/seasighly/yugang-d@v1.3.5/install.ps1 | iex"
```

安装脚本会自动：

1. 检查 Windows 版本 / 64 位
2. 检查 **WebView2 运行时**，缺了自动装（winget，失败则退回官方引导安装包）
3. 检查 **Node.js / DSH**，缺了自动装（浮窗需要）
4. 从 GitHub Releases 下载最新包，装到 `%LOCALAPPDATA%\YuGangD`
5. 创建桌面 / 开始菜单快捷方式并启动

卸载：删除 `%LOCALAPPDATA%\YuGangD` 和两个快捷方式即可。

---

## 热键

| 热键 | 作用 |
|---|---|
| `Ctrl + D` | 浮窗置顶 ⇄ 收回 |
| `Ctrl + Alt + Q` | 退出 |
| `Ctrl + Alt + H` | 隐藏 / 显示壁纸 |

## 托盘菜单

- **隐藏任务栏**：连任务栏一起藏掉，画面自动铺满整屏
- **跳过切换动画**：直接切两个模式（带 260ms 交叉溶解）
- **标定模式**：重新标定热区（点边界、回车提交）
- **重启浮层 DSH**：重新取 token 刷新浮窗
- **重新加载 / 退出**

## 配置文件

```
%APPDATA%\鱼缸D\settings.ini
```

```ini
skip=0
overlay=follow
```

## 运行要求

| 项 | 说明 |
|---|---|
| 系统 | Windows 10/11 x64 |
| WebView2 | 安装脚本会自动补 |
| DSH | 需运行在 `127.0.0.1:331`，浮窗才有内容；没有也能当纯壁纸用 |

## 已知限制

- 浮窗和浏览器共用同一个 DSH 会话数据，同一个对话不能两边同时打开（DSH 文件独占锁）
- 浮窗 token 从 `C:\鱼池\logs\dsh-331.log` 读取，路径写死在源码里
- 小鲸鱼挂件由 DSH 侧的 `dsh-whale-widget` 插件提供，只在浮窗里出现

## 源码编译

`src/` 是全部 C# 源码，用 .NET Framework 自带的 `csc.exe`：

```powershell
csc /target:winexe /platform:x64 /out:鱼缸D.exe /r:Microsoft.Web.WebView2.Core.dll /r:Microsoft.Web.WebView2.WinForms.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll src\*.cs
```

## License

MIT（`release/` 里的美术素材随包分发，仅用于运行本程序）