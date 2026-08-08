# Build scripts (Windows + MSYS2)

Host: **Windows**. Shell: **MSYS2 bash** (`C:\msys64\usr\bin\bash.exe`).  
Compile: **Zig** `zig cc -target x86_64-windows-gnu`.  
Final link (libvpl C++): MinGW **g++** via `patch-link-gpp.sh`.

## One-shot

```powershell
$env:PATH = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links;" + $env:PATH
C:\msys64\usr\bin\bash.exe -lc 'cd /path/to/capto-ffmpeg && ./scripts/build-all.sh'
```

| Step | Script |
|------|--------|
| Deps | `build-deps.sh` — x264, ffnvcodec, AMF headers, libvpl |
| AMF headers | `fetch-amf-headers.sh` (API + jsDelivr; avoids huge AMF clone) |
| FFmpeg | `build-windows.sh` — Capto whitelist configure + make |
| Link patch | `patch-link-gpp.sh` — MinGW g++ as `LD`/`LDXX` |
| Audit | `audit-dlls.sh` — import table allowlist |
| Smoke | `smoke.sh` — encoders / filters / protocols; asserts **no libx265** |

Output: `out/ffmpeg.exe` + `TAURI_BIN_ALIAS` copy.

## Prerequisites

- Zig version from `versions.env`
- MSYS2: `make`, `pkgconf`, `git`, `nasm`, `binutils`
- MinGW-w64: `cmake`, `ninja`, `gcc`/`g++` (libvpl)
- Python 3 on PATH (AMF header fetch)

## Notes

- GPU: NVENC/AMF = headers + runtime `LoadLibrary`; QSV = static **libvpl** dispatcher
- `patch-ffmpeg-makefile.sh` — H264_SEI ↔ `aom_film_grain.o` if still needed upstream
- No FreeType / `drawtext` / `dshow`
