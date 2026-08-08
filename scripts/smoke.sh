#!/usr/bin/env bash
# Assert Capto-required encoders/filters/protocols exist in the built binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

EXE="${1:-${OUT}/ffmpeg.exe}"
if [[ ! -f "${EXE}" ]]; then
  echo "missing ${EXE}" >&2
  exit 1
fi

RUN=()
if [[ "$(uname -s)" == "Linux" ]]; then
  if command -v wine64 >/dev/null 2>&1; then
    RUN=(wine64)
  elif command -v wine >/dev/null 2>&1; then
    RUN=(wine)
  else
    echo "no wine; doing PE string smoke only"
    for needle in libx264 h264_nvenc h264_amf h264_qsv hevc_nvenc hevc_amf hevc_qsv aac gif scale palettegen amix rawvideo f32le; do
      if ! strings "${EXE}" | grep -q "${needle}"; then
        echo "missing string: ${needle}" >&2
        exit 1
      fi
      echo "string ok: ${needle}"
    done
    echo "string smoke passed"
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

need_in -encoders libx264 h264_nvenc h264_amf h264_qsv hevc_nvenc hevc_amf hevc_qsv gif aac
need_in -filters scale fps split palettegen paletteuse volume amix
# Soft HEVC must stay out — Capto HEVC is GPU-only
if echo "$("${RUN[@]}" "${EXE}" -hide_banner -encoders 2>&1 || true)" | grep -Fq libx265; then
  echo "fail: libx265 must not be present (HEVC is GPU-only)" >&2
  exit 1
fi
echo "ok: no libx265"

text_demux="$("${RUN[@]}" "${EXE}" -hide_banner -demuxers 2>&1 || true)"
text_proto="$("${RUN[@]}" "${EXE}" -hide_banner -protocols 2>&1 || true)"
echo "${text_demux}" | grep -Eq 'rawvideo' || { echo "missing rawvideo demuxer" >&2; exit 1; }
echo "${text_demux}" | grep -Eq 'f32le' || { echo "missing f32le demuxer" >&2; exit 1; }
echo "ok demuxers: rawvideo/f32le"
for p in file pipe tcp; do
  echo "${text_proto}" | grep -Eq "(^|[[:space:]])${p}($|[[:space:]])" \
    || { echo "missing protocol: ${p}" >&2; echo "${text_proto}" >&2; exit 1; }
  echo "ok protocol: ${p}"
done

# Capto no longer needs dshow in the sidecar
if echo "$("${RUN[@]}" "${EXE}" -hide_banner -devices 2>&1 || true)" | grep -Fq dshow; then
  echo "warn: dshow still present (unused by Capto recording)" >&2
fi

echo "smoke passed"
