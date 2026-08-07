# capto-ffmpeg

Capto 专用、精简、尽量静态独立的 Windows `ffmpeg.exe` 构建与发布仓库。

本仓与 Capto 主工程分离：单独 tag / GitHub Release，产物供桌面端作为 Tauri `externalBin` sidecar 使用。

> 状态：Windows + Zig 0.16.0 本地构建已跑通（`out/ffmpeg.exe`）。  
> **能力目录以 [docs/CAPABILITIES.md](docs/CAPABILITIES.md) 为准。**

## 构建

```powershell
$env:PATH = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links;" + $env:PATH
C:\msys64\usr\bin\bash.exe -lc 'cd /d/AIWorkspace/capto-ffmpeg && ./scripts/build-all.sh'
```

详见 [scripts/README.md](scripts/README.md)。

## 目标

- 单个 `ffmpeg.exe`：第三方库静态链进，零附带 MinGW / x264 DLL
- 工具链：钉死版本的 **Zig `zig cc`**，目标 `x86_64-windows-gnu`
- CI 导入表审计：仅允许 Windows 系统 DLL；GPU 驱动运行时 `LoadLibrary`

## 能力一览（MVP · 2026-08-08）

完整表见 [docs/CAPABILITIES.md](docs/CAPABILITIES.md)。摘要：

| Capto 功能 | FFmpeg |
|------------|--------|
| 屏采（DXGI）+ 进程内摄像头 PiP | `rawvideo` + `bgra` + `pipe:0`（**无 dshow**） |
| 麦 / 环回 | `f32le` + `tcp` → `volume`/`amix` → `aac` |
| 点击 / 按键 overlay | **不经过 FFmpeg** |
| MP4 | `libx264` / NVENC / AMF；frag → faststart remux |
| GIF | `scale`/`fps`/`palette*` + `gif` |
| 仅音频 | `-vn` + `aac` → m4a |

**本版去掉：** `dshow`、`overlay`/`hflip`/`null`、FreeType、`libx265`、QSV。

## 构建期依赖（计划）

| 依赖 | 方式 |
|------|------|
| FFmpeg 源码 | 钉死 tag，白名单 configure |
| x264 | 静态 `.a` 链进 |
| ffnvcodec-headers / AMF headers | 仅头文件 |
| QSV | 优先 runtime-load；破坏单文件则裁掉 |
| Zig + nasm | CI 工具，不进发布包 |

## 仓库布局（规划）

```text
docs/CAPABILITIES.md          # 白名单（已维护）
versions.env
scripts/…                     # 构建尚未接线
.github/workflows/…
```

## 许可

FFmpeg + libx264 → **GPL**。本仓发布 LICENSE / NOTICE；与 Capto（MIT）主体许可分离。
