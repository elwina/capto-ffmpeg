# capto-ffmpeg

精简、尽量静态独立的 Windows `ffmpeg.exe` 构建与发布仓库（白名单面向录屏场景）。

> **Status:** Windows + Zig 0.16.0 · FFmpeg **n9.0** · x86_64 + aarch64  
> Capability whitelist: [docs/CAPABILITIES.md](docs/CAPABILITIES.md)

## What’s in the binary

- **Pipe / network:** `file`, `pipe`, `tcp` · demux `rawvideo`, `f32le` · mux `mp4` / `gif` / `m4a`
- **H.264:** `libx264` + `h264_nvenc` / `h264_amf` / `h264_qsv` (QSV on x86_64)
- **HEVC:** `hevc_nvenc` / `hevc_amf` / `hevc_qsv` only (**no `libx265`**)
- **GIF / audio:** palette filters · `aac`
- **GPU:** NVIDIA/AMF headers-only; Intel **libvpl** on x86_64; vendor runtimes `LoadLibrary` at encode time
- **Out:** `dshow`, FreeType/`drawtext`, overlay/hflip

## Versioning & GitHub Actions

Semver tags owned by this repo:

```text
v0.1.0
v0.2.0
…
```

Upstream pins live in `versions.env`.

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [CI](.github/workflows/ci.yml) | `push`/`PR` to `main`, manual | Build **x86_64 + aarch64** → audit → smoke (**no** Release) |
| [Release](.github/workflows/release.yml) | tag `v*.*.*`, or manual dry-run | Same matrix → **Artifact Attestations** → GitHub Release |

### Release assets

| File | Notes |
|------|--------|
| `ffmpeg-windows-x86_64.exe` | NVENC/AMF/QSV hooks + libx264 |
| `ffmpeg-windows-aarch64.exe` | NVENC/AMF hooks + libx264 (no Intel QSV) |
| `SHA256SUMS` / `LICENSE` / `NOTICE` / `versions.env` | Checksums + license metadata |

```bash
# After CI is green on main:
git tag v0.1.0
git push origin v0.1.0

sha256sum -c SHA256SUMS
gh attestation verify ffmpeg-windows-x86_64.exe -R <owner>/capto-ffmpeg
```

## Local build (Windows + MSYS2)

```powershell
$env:PATH = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links;" + $env:PATH
C:\msys64\usr\bin\bash.exe -lc 'cd /path/to/capto-ffmpeg && ./scripts/build-all.sh'

# optional:
# ARCH_OVERRIDE=aarch64 ./scripts/build-all.sh
```

Pipeline: `build-deps` → `build-windows` → `audit-dlls` → `smoke`  
Output: `out/ffmpeg.exe` + `out/ffmpeg-windows-<arch>.exe`

Details: [scripts/README.md](scripts/README.md)

### Host tools

- Zig (pinned in `versions.env`)
- MSYS2: `make`, `pkgconf`, `git`, `nasm`, `binutils`
- MinGW `cmake` / `ninja` / `g++` (x86_64 **libvpl** + final C++ link)

## License

Shipped binaries are **GPL-2.0** (`--enable-gpl` + libx264). See [LICENSE](LICENSE),
[NOTICE](NOTICE), and [licenses/THIRD_PARTY.md](licenses/THIRD_PARTY.md).

Vendor GPU drivers are **not** redistributed.
