#!/usr/bin/env bash
# Assert Capto-required encoders/filters/indevs exist in the built binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

EXE="${1:-${OUT}/ffmpeg.exe}"
if [[ ! -f "${EXE}" ]]; then
  echo "missing ${EXE}" >&2
  exit 1
fi

# On Linux CI, Windows PE may still run under wine; prefer native Windows or wine.
RUN=()
if [[ "$(uname -s)" == "Linux" ]]; then
  if command -v wine64 >/dev/null 2>&1; then
    RUN=(wine64)
  elif command -v wine >/dev/null 2>&1; then
    RUN=(wine)
  else
    echo "no wine; doing PE string smoke only"
    for needle in libx264 h264_nvenc h264_amf aac gif scale overlay hflip palettegen amix dshow rawvideo; do
      if ! strings "${EXE}" | grep -q "${needle}"; then
        echo "missing string: ${needle}" >&2
        exit 1
      fi
      echo "string ok: ${needle}"
    done
    echo "string smoke passed (install wine for fuller checks)"
    exit 0
  fi
fi

"${RUN[@]}" "${EXE}" -hide_banner -version | head -n 5

need_in() {
  local section="$1"
  shift
  local text
  text="$("${RUN[@]}" "${EXE}" -hide_banner "${section}" 2>&1 || true)"
  local name
  for name in "$@"; do
    if ! grep -Fq "${name}" <<<"${text}"; then
      echo "missing in ${section}: ${name}" >&2
      exit 1
    fi
    echo "ok ${section}: ${name}"
  done
}

need_in -encoders libx264 h264_nvenc h264_amf gif aac
need_in -filters scale null overlay hflip fps split palettegen paletteuse volume amix
# demuxers / devices / protocols (fatal for Capto if missing)
text_dev="$("${RUN[@]}" "${EXE}" -hide_banner -devices 2>&1 || true)"
text_demux="$("${RUN[@]}" "${EXE}" -hide_banner -demuxers 2>&1 || true)"
text_proto="$("${RUN[@]}" "${EXE}" -hide_banner -protocols 2>&1 || true)"
echo "${text_dev}" | grep -Fq dshow || { echo "missing dshow indev" >&2; exit 1; }
echo "ok devices: dshow"
echo "${text_demux}" | grep -Eq 'rawvideo' || { echo "missing rawvideo demuxer" >&2; exit 1; }
echo "${text_demux}" | grep -Eq 'f32le' || { echo "missing f32le demuxer" >&2; exit 1; }
echo "ok demuxers: rawvideo/f32le"
for p in file pipe tcp; do
  echo "${text_proto}" | grep -Eq "(^|[[:space:]])${p}($|[[:space:]])" \
    || { echo "missing protocol: ${p}" >&2; echo "${text_proto}" >&2; exit 1; }
  echo "ok protocol: ${p}"
done

echo "smoke passed"
