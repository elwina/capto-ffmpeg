# Placeholder — real recipes land before first CI build.

## Planned scripts

- `zig-env.sh` — export `CC`/`CXX`/`AR` via pinned Zig
- `build-deps.sh` — static x264 (+ optional headers)
- `configure-capto.sh` — `--disable-everything` whitelist
- `build-windows.sh` — orchestrate deps → ffmpeg → strip
- `audit-dlls.sh` — PE import audit (system DLLs only)

Do not run a full build until Capto’s FFmpeg argv surface stabilizes.
