# capto-ffmpeg

Capto 专用、精简、尽量静态独立的 Windows `ffmpeg.exe` 构建与发布仓库。

Minimal, Capto-oriented Windows FFmpeg sidecar (Tauri `externalBin`). Separate
from the Capto app repo so GPL tooling stays isolated from Capto’s app license.

> **Status:** Windows + Zig 0.16.0 · FFmpeg **n9.0** · DLL audit + smoke green  
> Capability whitelist: [docs/CAPABILITIES.md](docs/CAPABILITIES.md)

## Why this exists

| Common “full” FFmpeg builds | This repo |
|-----------------------------|-----------|
| Large, many unused codecs/devices | `--disable-everything` + Capto whitelist |
| Often many companion DLLs | Single `ffmpeg.exe`, system-DLL audit |
| Random system/PATH installs | Pinned tags in `versions.env` |
| Soft HEVC (`libx265`) common | HEVC = **GPU only** (nvenc / amf / qsv) |

## What’s enabled (summary)

- **Pipe / network:** `file`, `pipe`, `tcp` · demux `rawvideo`, `f32le` · mux `mp4` / `gif` / `m4a`
- **H.264:** `libx264` + `h264_nvenc` / `h264_amf` / `h264_qsv`
- **HEVC:** `hevc_nvenc` / `hevc_amf` / `hevc_qsv` only (**no `libx265`**)
- **GIF / audio:** palette filters · `aac`
- **GPU policy:** NVIDIA/AMF headers-only hooks; Intel **libvpl** dispatcher static; vendor GPU runtimes `LoadLibrary` at encode time
- **Not included:** `dshow`, FreeType/`drawtext`, overlay/hflip (Capto composites webcam in-process)

## Build (Windows + MSYS2)

```powershell
$env:PATH = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links;" + $env:PATH
C:\msys64\usr\bin\bash.exe -lc 'cd /path/to/capto-ffmpeg && ./scripts/build-all.sh'
```

Pipeline: `build-deps.sh` → `build-windows.sh` → `audit-dlls.sh` → `smoke.sh`  
Output: `out/ffmpeg.exe` (+ Tauri alias from `TAURI_BIN_ALIAS` in `versions.env`)

Details: [scripts/README.md](scripts/README.md)

### Host tools

- Zig (pinned in `versions.env`)
- MSYS2: `make`, `pkgconf`, `git`, `nasm`, `binutils`
- MinGW `cmake` / `ninja` / `g++` (for static **libvpl** + final C++ link)

## Consume from Capto

Copy Release/`out` binary into Capto’s sidecar directory (see Capto’s
`scripts/copy-ffmpeg.ps1` or equivalent). Capto should keep probing encoders;
missing GPU runtimes simply mark HW encoders unavailable.

## Repository layout

```text
versions.env              # pinned FFmpeg / x264 / headers / libvpl
docs/CAPABILITIES.md      # whitelist synced with Capto recording argv
scripts/                  # deps, configure, build, audit, smoke
licenses/THIRD_PARTY.md   # dependency map
LICENSE                   # GPL-2.0 (combined binary)
NOTICE                    # redistribution notes
out/ffmpeg.exe            # local build artifact (not committed)
```

## License

**Redistributable `ffmpeg.exe` (this build): GPL-2.0** — see [LICENSE](LICENSE)
and [NOTICE](NOTICE). FFmpeg is configured with `--enable-gpl` and links
**libx264**.

- Do **not** treat Capto’s application license (e.g. MIT) as covering this binary.
- When shipping Capto with this sidecar, include `LICENSE` + `NOTICE` (and keep
  corresponding source / pins available per GPL).
- Vendor GPU drivers are **not** redistributed; see NOTICE.

Build scripts in this repo are provided to produce that GPL binary; treat the
**shipped artifact** as GPL.
