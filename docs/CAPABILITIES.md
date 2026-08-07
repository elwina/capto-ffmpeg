# Capability whitelist (synced from Capto)

Source of truth for configure `--enable-*`. Re-check Capto `crates/capto-core/src/ffmpeg_args.rs` before enabling a build.

## Required (current Capto recording path)

### Demux / indev / protocols

- `rawvideo` (demuxer) + pixel format `bgra`
- protocol `pipe` (`pipe:0` stdin frames from DXGI pump)
- `f32le` + protocol `tcp` (PCM from Capto WASAPI)
- indev `dshow` (webcam PiP); capture size `640x480`, `yuyv422`

### Filters

- `scale`, `null`, `overlay`, `hflip`
- `fps`, `split`, `palettegen`, `paletteuse`
- `volume`, `amix`

### Encoders / muxers

- `libx264`, `h264_nvenc`, `h264_qsv`, `h264_amf`, `gif`
- `aac`
- mux `mp4`, `gif`

## Explicitly out (current Capto)

- `gdigrab` — screen capture is DXGI → rawvideo, not GDI grab
- `drawtext` / FreeType / Fontconfig — no burned-in timer/text in FFmpeg
- wasapi/dshow **audio** — audio is native Capto → TCP PCM
- `libx265` / HEVC software — optional later; HW HEVC headers-only possible later

## Runtime (not shipped)

- Windows system DLLs
- Vendor GPU encode DLLs via LoadLibrary
- System fonts — N/A while drawtext is disabled
