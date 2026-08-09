# capto-ffmpeg

Slim, mostly-static Windows `ffmpeg.exe` builds for screen-recording sidecars (capability whitelist).

> **Status:** Windows · Zig 0.16.0 · FFmpeg **n9.0** · **x86_64 + aarch64**  
> Capability whitelist: [docs/CAPABILITIES.md](docs/CAPABILITIES.md)

## What’s in the binary

- **Pipe / network:** `file`, `pipe`, `tcp` · demux `rawvideo`, `pcm_f32le` · mux `mp4` / `gif` / `m4a`
- **H.264:** `libx264` + `h264_nvenc` / `h264_amf` / `h264_qsv` (QSV on x86_64 only)
- **HEVC:** `hevc_nvenc` / `hevc_amf` / `hevc_qsv` only (**no `libx265`**)
- **GIF / audio:** palette filters · `aac`
- **GPU:** NVIDIA/AMF headers only; Intel **libvpl** on x86_64; vendor runtimes via `LoadLibrary` at encode time
- **Not included:** `dshow`, FreeType/`drawtext`, overlay/hflip, lavfi, and most of the full FFmpeg surface

## Versioning

**Major tracks Capto’s product major.** This sidecar is not a separate product line.

| Capto | This repo |
|-------|-----------|
| Pre-1.0 (unreleased) | `v0.y.z-nX.Y` — e.g. **`v0.1.0-n9.0`** |
| Capto **1.0** ships | **`v1.0.0-n9.0`** (same FFmpeg pin) / bump `-n…` when the pin moves |
| Capto **2.0** | `v2.0.0-n…` |

| Part | Meaning |
|------|---------|
| **MAJOR** | Same as Capto’s major (`0` while Capto is pre-release; `1` when Capto 1.0 ships) |
| **MINOR** | Sidecar capability / packaging bumps under that Capto major |
| **PATCH** | Rebuild, toolchain, or bugfix with the same surface |
| **`-n9.0`** | FFmpeg pin from [`versions.env`](versions.env) (`FFMPEG_TAG=n9.0`), kept in the tag for humans and release notes |

```text
v0.1.0-n9.0   ← first dual-arch release (Capto still 0.x)
v0.1.1-n9.0   patch / rebuild, same pin
v0.2.0-n9.0   additive sidecar bump under Capto 0.x
v1.0.0-n9.0   Capto 1.0 — lockstep major
v1.0.0-n9.1   same Capto major, newer FFmpeg pin only
```
## Benchmark (indicative)

Local laptop check: **Capto CI x86_64 artifact** vs **gyan.dev FFmpeg 8.1.2 full**, same 1080p60 / 5s raw input, **RTX 3070 Laptop**. Not a CI gate — numbers vary by machine/driver.

| Metric | Capto (~7.7 MB) | gyan full (~231 MB) |
|--------|-----------------|---------------------|
| Binary size | **~7.7 MB** | ~231 MB |
| `-version` warm start | ~33 ms | ~36 ms |
| 1-frame `h264_nvenc` | ~291 ms | ~295 ms |
| 5s `h264_nvenc` (p4, 8M) | ~2.04 s · ~5.2× | ~2.03 s · ~5.5× |
| 5s `hevc_nvenc` (p4, 8M) | ~2.03 s · ~5.0× | ~2.03 s · ~4.9× |
| 5s `libx264` ultrafast | ~1.02 s · ~7.7× | ~1.01 s · ~7.8× |

Takeaway: encode throughput matches a full Windows build on this GPU; the win is size (~30× smaller) and a locked whitelist.

## GitHub Actions

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [CI](.github/workflows/ci.yml) | `push` / `PR` to `main`, manual | Build **x86_64 + aarch64** → audit → smoke (**no** Release) |
| [Release](.github/workflows/release.yml) | tag `v*.*.*`, or manual dry-run | Same matrix → **Artifact Attestations** → GitHub Release |

### Release assets

| File | Notes |
|------|--------|
| `ffmpeg-windows-x86_64.exe` | NVENC / AMF / QSV hooks + libx264 |
| `ffmpeg-windows-aarch64.exe` | NVENC / AMF hooks + libx264 (no Intel QSV) |
| `SHA256SUMS` / `LICENSE` / `NOTICE` / `versions.env` | Checksums + license metadata |

```bash
# After CI is green on main:
git tag v0.1.0-n9.0
git push origin v0.1.0-n9.0

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
