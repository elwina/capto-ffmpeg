# Capto → FFmpeg capability catalog

**Synced:** 2026-08-08  
**FFmpeg pin:** `n9.0`  
**Sources:**

- `Capto/crates/capto-core/src/ffmpeg_args.rs`
- `Capto/crates/capto-core/src/session.rs` (DXGI pump, frag→faststart remux)
- `Capto/crates/capto-capture` (webcam PiP composited in-process)
- `Capto/crates/capto-encode/src/lib.rs`

---

## 1. Pipeline (current Capto)

```text
DXGI + Rust webcam PiP + cursor  --bgra-->  ffmpeg stdin (rawvideo / pipe:0)
WASAPI mic/loopback              --f32le-->  ffmpeg tcp:// (volume/amix → aac)
Tauri click/key overlay window   --------->  (already in DXGI pixels)
                                              │
                                              ├─ MP4  (libx264 | *_nvenc | *_amf | *_qsv) + frag moov
                                              ├─ GIF  (palette*)
                                              └─ m4a  (aac only)
                                              │
                                   stop → remux -c copy +faststart
```

| Capto feature | FFmpeg? | Notes |
|---------------|---------|-------|
| Screen / region / window | Yes | Capto crops; FFmpeg sees fixed `rawvideo` |
| Cursor | No | Capto composites into BGRA |
| Click / key overlay | No | Transparent window in DXGI frames |
| Webcam PiP | **No** | Rust Media Foundation → composite before pipe (**not dshow**) |
| Mic / loopback | Yes | `f32le` + `tcp` + `volume`/`amix`/`aac` |
| MP4 / GIF / audio-only | Yes | |
| Screenshot | No | |

---

## 2. Required configure whitelist

Order: **`--disable-everything` first**, then enables. Also `--enable-network` for `tcp`.

### Protocols
`file`, `pipe`, `tcp`

### Demuxers
| Configure name | Runtime `-f` |
|----------------|--------------|
| `rawvideo` | `rawvideo` |
| `pcm_f32le` | `f32le` |
| `mov` | remux input |

### Muxers
`mp4`, `gif`, `ipod` (m4a)

### Encoders
| Encoder | Role |
|---------|------|
| `libx264` | Soft H.264 fallback |
| `h264_nvenc` / `hevc_nvenc` | NVIDIA — ffnvcodec headers, `LoadLibrary` |
| `h264_amf` / `hevc_amf` | AMD — AMF headers, `LoadLibrary` |
| `h264_qsv` / `hevc_qsv` | Intel — static **VPL dispatcher** only; GPU runtime at encode time |
| `gif`, `aac` | GIF / audio |

**No `libx265`** — HEVC is GPU-only.

### Decoders
`rawvideo`, `pcm_f32le`

### Filters
`scale`, `fps`, `split`, `palettegen`, `paletteuse`, `volume`, `amix`, `aformat`, `aresample`

### Other
`swscale`, `swresample`, `avfilter`, `avformat`, `avcodec`, `avutil`  
parsers/bsf: `h264`, `hevc`, `aac`, `h264_mp4toannexb`, `hevc_mp4toannexb`, `aac_adtstoasc`  
pix: `bgra`, `yuv420p`

### Flags Capto sets (not separate components)
`-use_wallclock_as_timestamps 1`, `-fps_mode cfr`, frag `movflags`, remux `+faststart`

---

## 3. GPU policy (hooks, not vendor SDKs)

| Vendor | Build-time | Runtime |
|--------|------------|---------|
| NVIDIA | `ffnvcodec` headers | `nvcuda` / NVENC DLLs via `LoadLibrary` |
| AMD | AMF headers | `amfrt64.dll` via `LoadLibrary` |
| Intel | open-source **libvpl** dispatcher (static `.a`, **x86_64 only**) | Intel VPL / Media SDK impl DLLs |


Do **not** ship vendor GPU runtimes or MinGW/x264 DLLs inside the Capto sidecar.

---

## 4. Explicitly OUT

| Drop | Why |
|------|-----|
| `dshow` / `avdevice` | Webcam no longer via FFmpeg |
| `overlay`, `hflip`, `null` | PiP not in filter graph |
| FreeType / `drawtext` | Still cut |
| `libx265` | HEVC = GPU only |
| `lavfi` | Dev-only stub on non-Windows |
| `yuyv422` for dshow | N/A |

---

## 5. Smoke must assert

- protocols: `file`, `pipe`, `tcp` (Input + Output)
- demuxers: `rawvideo`, `f32le`
- encoders: `libx264`, `h264_nvenc`, `h264_amf`, `h264_qsv`, `hevc_nvenc`, `hevc_amf`, `hevc_qsv`, `gif`, `aac`
- **must not** list `libx265`
- filters: `scale`, `fps`, `split`, `palettegen`, `paletteuse`, `volume`, `amix`
- **must not require** `dshow`
