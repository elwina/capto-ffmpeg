# Capto → FFmpeg capability catalog

**Synced:** 2026-08-07  
**Sources (re-check before every build):**

- `Capto/crates/capto-core/src/ffmpeg_args.rs` — record argv
- `Capto/crates/capto-core/src/session.rs` — DXGI pump, stop/EOF, frag→faststart remux
- `Capto/crates/capto-encode/src/lib.rs` — encoder probe / dshow list / spawn
- `Capto/README.md` — product matrix (P0 / P1 / cut)

This file is the configure whitelist source of truth for `capto-ffmpeg`.

---

## 1. End-to-end pipeline (what Capto does vs FFmpeg)

```text
DXGI frame pump (Capto)  --bgra-->  ffmpeg stdin  (rawvideo / pipe:0)
WASAPI mic/loopback      --f32le-->  ffmpeg tcp://  (mix → aac)
dshow webcam (optional)  --------->  ffmpeg         (scale/hflip → overlay)
Tauri transparent window --------->  (pixels in DXGI frames; NOT FFmpeg text)
                                     │
                                     ├─ MP4  (libx264 | nvenc | qsv | amf) + frag moov
                                     ├─ GIF  (palettegen/paletteuse)
                                     └─ m4a  (audio-only aac)
                                     │
                          stop → remux -c copy +faststart (MP4 only)
```

| Capto product feature | Enters FFmpeg? | How |
|----------------------|----------------|-----|
| Display / window / region capture | Yes | Capto crops/scales in DXGI pump; FFmpeg only sees fixed-size `rawvideo` |
| Cursor on/off | No (Capto composites cursor into BGRA) | |
| Click highlight | No | React overlay window → captured in DXGI frames |
| Keystroke chips | No | Same; **no FreeType / drawtext** |
| Elapsed timer on video | No | Cut from product; UI-only if shown |
| Webcam PiP | Yes | `dshow` + `overlay` (+ optional `hflip`) |
| Mic + system loopback | Yes | Capto WASAPI → `f32le` over `tcp://`; FFmpeg `volume`/`amix`/`aac` |
| MP4 encode | Yes | H.264 software/HW + fragmented `movflags`, then remux |
| GIF | Yes | palette filters + `gif` encoder |
| Audio-only | Yes | `-vn` + `aac` → `.m4a` |
| Screenshot | No | Capto / xcap, not FFmpeg |
| P1 text/image burn-in | Not implemented in argv yet | Would need `drawtext`/image overlay later |

---

## 2. Required FFmpeg components (MVP build)

### 2.1 Protocols

| Name | Use |
|------|-----|
| `file` | output path + remux temp file |
| `pipe` | `pipe:0` screen frames |
| `tcp` | localhost PCM from Capto |

Configure order: **`--disable-everything` first**, then `--enable-network` + `--enable-protocol=file|pipe|tcp`. Enabling protocols before `disable-everything` is a no-op (empty `-protocols` list).

### 2.2 Devices / demuxers / formats (input)

| Name | Use |
|------|-----|
| `rawvideo` | Screen stdin demuxer |
| `pcm_f32le` (configure) / runtime name `f32le` | PCM demuxer (`-f f32le`) |
| `dshow` | Webcam indev + `-list_devices` |
| `mov` / `mp4` demux | Frag MP4 remux input (`-i … -c copy`) |

Pixel formats involved (must be available in build):

| Pix fmt | Use |
|---------|-----|
| `bgra` | DXGI → rawvideo input |
| `yuyv422` | dshow webcam pin |
| `yuv420p` | H.264 encode output |

### 2.3 Filters

| Name | Use |
|------|-----|
| `scale` | Even dimensions; PiP size; GIF `flags=lanczos` |
| `null` | GIF graph label hop `[0:v]null[v0]` |
| `overlay` | Webcam PiP (`shortest=1`) |
| `hflip` | Mirrored webcam |
| `fps` | GIF frame rate cap |
| `split` | GIF palette path |
| `palettegen` / `paletteuse` | GIF |
| `volume` | Mic gain vs loopback |
| `amix` | Dual PCM mix (`duration=shortest`) |

### 2.4 Encoders

| Name | Role | Link style |
|------|------|------------|
| `libx264` | Software H.264 fallback (required) | Static x264 |
| `h264_nvenc` | NVIDIA | Headers + runtime driver |
| `h264_qsv` | Intel | Prefer runtime-load; drop if breaks single-exe |
| `h264_amf` | AMD | Headers + runtime driver |
| `gif` | GIF video | Built-in |
| `aac` | Audio (MP4 / m4a) | Built-in FFmpeg AAC OK |

Probed by Capto but **not required for MVP binary** (optional later):

| Name | Note |
|------|------|
| `hevc_nvenc` / `hevc_qsv` / `hevc_amf` | Cheap if headers already present; UI may list if enabled |
| `libx265` | Heavy; **omit** until product needs it |

### 2.5 Muxers / bitstream

| Name | Use |
|------|-----|
| `mp4` | Primary recording + remux target (also covers `.m4a` audio-only) |
| `gif` | GIF output |
| stream copy (`-c copy`) | Remux only; no re-encode |

### 2.6 Output / mux flags Capto sets (must work, not separate components)

- Record MP4: `-movflags +frag_keyframe+empty_moov+default_base_moof`
- Remux: `-movflags +faststart`
- `-shortest` so screen pipe EOF ends encode while dshow still open
- `-fps_mode cfr`
- Encoder args: `veryfast`/`crf` (x264), nvenc `p4`/`vbr`/`cq`, qsv `global_quality`, amf `cqp`

---

## 3. Explicitly OUT of MVP build

| Item | Why |
|------|-----|
| `gdigrab` | Screen path is DXGI → rawvideo |
| FreeType / Fontconfig / `drawtext` | No FFmpeg text; keys/clicks are UI overlay |
| wasapi / dshow **audio** capture | Capto native WASAPI → TCP |
| `libx265` | Size; not on critical path |
| `ffplay` | Unused |
| Broad demuxer/decoder/network set | Sidecar is encode/mux focused |
| Bundled fonts / CUDA / full QSV runtime | Not shipped |

---

## 4. Build-time external deps

| Dep | MVP? | How |
|-----|------|-----|
| FFmpeg sources | Yes | Pinned tag |
| x264 | Yes | Static `.a` into exe |
| ffnvcodec-headers | Yes (NVENC) | Headers only |
| AMF headers | Yes (AMF) | Headers only |
| oneVPL / mfx | Only if QSV kept without DLL | Prefer runtime-load or omit QSV |
| zlib / FreeType | **No** | No drawtext |
| Zig + nasm | Yes | Toolchain only |

---

## 5. P1 watchlist (do not enable until Capto argv lands)

From Capto README P1:

- Static text / image burn-in → likely `drawtext` + FreeType and/or `movie`/`overlay` image input
- Until then, keep them out of the static binary

---

## 6. Configure sketch (informational)

Exact script TBD; intent:

```text
--disable-everything --disable-autodetect --enable-static --disable-shared
--enable-gpl --enable-libx264
--enable-protocol=pipe,tcp,file
--enable-demuxer=rawvideo,mov,…   # + f32le as format
--enable-indev=dshow
--enable-filter=scale,null,overlay,hflip,fps,split,palettegen,paletteuse,volume,amix
--enable-encoder=libx264,h264_nvenc,h264_qsv,h264_amf,gif,aac
--enable-muxer=mp4,gif
--enable-hwaccel / nvenc / amf as required by chosen FFmpeg version
+ pix fmt / parser bits needed for bgra, yuyv422, yuv420p, h264
```

Smoke assertions after build:

1. `-encoders` lists `libx264`, `h264_nvenc`, `h264_qsv`, `h264_amf`, `gif`, `aac`
2. `-filters` lists every filter in §2.3
3. `-demuxers` / `-indevs` include `rawvideo`, `dshow`
4. DLL import audit: system DLLs only
5. Manual: rawvideo pipe encode; dshow list; frag remux `-c copy -movflags +faststart`
