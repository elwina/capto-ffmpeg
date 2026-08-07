# capto-ffmpeg

Capto 专用、精简、尽量静态独立的 Windows `ffmpeg.exe` 构建与发布仓库。

本仓与 [Capto](https://github.com/) 主工程分离：单独 tag / GitHub Release，产物供桌面端作为 Tauri `externalBin` sidecar 使用。

> 状态：仓库已初始化，**构建脚本尚未落地**。能力白名单以 Capto 当前录制路径为准，会随主仓再调整。

## 目标

- 单个 `ffmpeg.exe`：第三方库静态链进，不附带 MinGW / x264 / freetype DLL
- 工具链：钉死版本的 **Zig `zig cc`**，目标 `x86_64-windows-gnu`
- CI 导入表审计：仅允许 Windows 系统 DLL；GPU 驱动运行时 `LoadLibrary`

## Capto 当前实际用到的能力（2026-08 对照主仓）

主路径已改为：**DXGI 泵帧 → stdin `rawvideo`（bgra）**，不再用 `gdigrab` 抓屏。  
摄像头 PiP：`dshow`。点击/按键 overlay 由 Capto 透明窗合成进画面，**不**走 FFmpeg `drawtext`。计时烧录已从产品矩阵移除。

| 类别 | 需要 | 说明 |
|------|------|------|
| 输入 | `rawvideo` + `bgra` + `pipe:0` | 屏幕帧 |
| 输入 | `f32le` + `tcp://` | 本机 PCM（mic / loopback） |
| 输入 | `dshow` + `yuyv422` | 摄像头 PiP |
| 滤镜 | `scale` `null` `overlay` `hflip` | PiP 缩放/镜像/叠加 |
| 滤镜 | `fps` `split` `palettegen` `paletteuse` | GIF |
| 滤镜 | `volume` `amix` | 双路音频混音 |
| 视频编码 | `libx264`；`h264_nvenc` / `h264_qsv` / `h264_amf`；`gif` | 软件回退 + 硬编探测 |
| 音频编码 | `aac` | |
| 封装 | `mp4`、`gif` | |

**当前不需要（可从精简包去掉）：**

- `gdigrab`（屏采已不走它）
- FreeType / `drawtext` / Fontconfig（无成片文字烧录）
- `libx265`（探测列表里有，可后补）
- wasapi/dshow **音频**采集（音频由 Capto 原生 WASAPI → TCP）

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
versions.env
scripts/zig-env.sh
scripts/build-deps.sh
scripts/configure-capto.sh
scripts/build-windows.sh
scripts/audit-dlls.sh
.github/workflows/build-release.yml
```

## 本地（构建就绪后）

```bash
# 将由 scripts/build-windows.sh 提供
```

## 许可

FFmpeg + libx264 → **GPL**。本仓发布 LICENSE / NOTICE；与 Capto（MIT）主体许可分离，sidecar 进程模型不分发进主程序静态链接。
