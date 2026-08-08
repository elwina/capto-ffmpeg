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

Output: `out/ffmpeg.exe` + `out/ffmpeg-windows-<arch>.exe`


- **CI** (`.github/workflows/ci.yml`): PR / `main` builds **x86_64 + aarch64**,
  audit + smoke, uploads artifacts (no Release).
- **Release** (`.github/workflows/release.yml`): tag `vX.Y.Z` rebuilds both,
  attests, publishes `ffmpeg-windows-x86_64.exe` + `ffmpeg-windows-aarch64.exe`.
- Shared: `.github/workflows/reusable-windows-build.yml` (matrix).
- Arch override locally: `ARCH_OVERRIDE=aarch64 ./scripts/build-all.sh`

## Prerequisites

- Zig version from `versions.env`
- MSYS2: `make`, `pkgconf`, `git`, `nasm`, `binutils`
- MinGW-w64: `cmake`, `ninja`, `gcc`/`g++` (libvpl)
- Python 3 on PATH (AMF header fetch)

## Notes

- GPU: NVENC/AMF = headers + runtime `LoadLibrary`; QSV = static **libvpl** dispatcher
- `patch-ffmpeg-makefile.sh` — H264_SEI ↔ `aom_film_grain.o` if still needed upstream
- No FreeType / `drawtext` / `dshow`
