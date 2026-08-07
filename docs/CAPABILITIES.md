# Capto → FFmpeg capability catalog

**Synced:** 2026-08-08  
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
                                              ├─ MP4  (libx264|nvenc|amf) + frag moov
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
`libx264`, `h264_nvenc`, `h264_amf`, `gif`, `aac`  
(QSV still omitted for single-exe; Capto probes it but build stays lean)

### Decoders
`rawvideo`, `pcm_f32le`

### Filters
`scale`, `fps`, `split`, `palettegen`, `paletteuse`, `volume`, `amix`, `aformat`, `aresample`

### Other
`swscale`, `swresample`, `avfilter`, `avformat`, `avcodec`, `avutil`  
parsers/bsf: `h264`, `aac`, `h264_mp4toannexb`, `aac_adtstoasc`  
pix: `bgra`, `yuv420p`

### Flags Capto sets (not separate components)
`-use_wallclock_as_timestamps 1`, `-fps_mode cfr`, frag `movflags`, remux `+faststart`

---

## 3. Explicitly OUT (vs previous build)

| Drop | Why |
|------|-----|
| `dshow` / `avdevice` | Webcam no longer via FFmpeg |
| `overlay`, `hflip`, `null` | PiP not in filter graph |
| FreeType / `drawtext` | Still cut |
| `libx265` / QSV | Size / DLL risk |
| `lavfi` | Dev-only stub on non-Windows |
| `yuyv422` for dshow | N/A |

---

## 4. Smoke must assert

- protocols: `file`, `pipe`, `tcp` (Input + Output)
- demuxers: `rawvideo`, `f32le`
- encoders: `libx264`, `h264_nvenc`, `h264_amf`, `gif`, `aac`
- filters: `scale`, `fps`, `split`, `palettegen`, `paletteuse`, `volume`, `amix`
- **must not require** `dshow`
