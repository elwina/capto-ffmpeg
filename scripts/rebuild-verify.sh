#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/c/Users/${USER:-elwin}/AppData/Local/Microsoft/WinGet/Links:${PATH}"
export PKG_CONFIG_PATH="$(pwd)/prefix/lib/pkgconfig"
sed -i 's|^prefix=.*|prefix=/d/AIWorkspace/capto-ffmpeg/prefix|' prefix/lib/pkgconfig/*.pc
./scripts/build-windows.sh
./scripts/audit-dlls.sh
./scripts/smoke.sh
echo "==== protocols ===="
./out/ffmpeg.exe -hide_banner -protocols
echo "==== demuxers (subset) ===="
./out/ffmpeg.exe -hide_banner -demuxers 2>&1 | grep -E 'f32le|rawvideo|mov' || true
