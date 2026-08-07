#!/usr/bin/env bash
# Fix upstream hole: H264_SEI calls aom film-grain helpers but only HEVC_SEI links the .o
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MK="${ROOT}/deps-src/ffmpeg/libavcodec/Makefile"
[[ -f "${MK}" ]] || { echo "missing ${MK}" >&2; exit 1; }
if grep -q 'CONFIG_H264_SEI).*aom_film_grain' "${MK}"; then
  echo "patch already applied"
  exit 0
fi
cp -f "${MK}" "${MK}.bak"
perl -i -pe 's/OBJS-\$\(CONFIG_H264_SEI\)(\s+)\+=(\s+)h264_sei\.o h2645_sei\.o$/OBJS-\$(CONFIG_H264_SEI)$1+=$2h264_sei.o h2645_sei.o aom_film_grain.o/' "${MK}"
grep 'CONFIG_H264_SEI' "${MK}" | head -3
