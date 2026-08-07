# Build scripts (Windows + MSYS2)

Host: **Windows**. Shell: **MSYS2 bash** (`C:\msys64\usr\bin\bash.exe`).
Compiler: system **Zig** (`winget`) via wrappers → `zig cc -target x86_64-windows-gnu`.

## One-shot

```powershell
$env:PATH = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links;" + $env:PATH
C:\msys64\usr\bin\bash.exe -lc 'cd /d/AIWorkspace/capto-ffmpeg && ./scripts/build-all.sh'
```

Steps: `build-deps.sh` → `build-windows.sh` → `audit-dlls.sh` → `smoke.sh`

Output: `out/ffmpeg.exe` (~6MB) + Tauri alias name.

## Prerequisites

- Zig 0.16.0
- MSYS2: `make`, `pkgconf`, `git`, `nasm`, `binutils` (`strings`)
- Optional: WinGet NASM

## Notes

- QSV omitted in v1 (DLL risk); NVENC/AMF headers-only
- `patch-ffmpeg-makefile.sh` links `aom_film_grain.o` for H264_SEI (upstream hole)
- No FreeType / drawtext
