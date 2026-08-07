#!/usr/bin/env bash
# Fetch FFmpeg, configure with Capto whitelist, link static ffmpeg.exe -> out/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/zig-env.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/configure-capto.sh"

jobs="$(nproc 2>/dev/null || echo 4)"

if [[ ! -f "${PREFIX}/lib/pkgconfig/x264.pc" && ! -f "${PREFIX}/lib/libx264.a" ]]; then
  echo "missing x264 in PREFIX; run scripts/build-deps.sh first" >&2
  exit 1
fi

echo "==> FFmpeg ${FFMPEG_TAG}"
FF_SRC="${DEPS_SRC}/ffmpeg"
if [[ -d "${FF_SRC}/.git" ]]; then
  git -C "${FF_SRC}" fetch --depth 1 origin tag "${FFMPEG_TAG}" || \
    git -C "${FF_SRC}" fetch --depth 1 origin "${FFMPEG_TAG}"
  git -C "${FF_SRC}" checkout -q FETCH_HEAD
else
  rm -rf "${FF_SRC}"
  mkdir -p "${FF_SRC}"
  git -C "${FF_SRC}" init
  git -C "${FF_SRC}" remote add origin https://github.com/FFmpeg/FFmpeg.git
  # Shallow tag fetch (full clone is huge / slow)
  if ! git -C "${FF_SRC}" fetch --depth 1 origin tag "${FFMPEG_TAG}"; then
    echo "primary fetch failed; retrying via ghproxy" >&2
    git -C "${FF_SRC}" remote set-url origin https://mirror.ghproxy.com/https://github.com/FFmpeg/FFmpeg.git
    git -C "${FF_SRC}" fetch --depth 1 origin tag "${FFMPEG_TAG}"
  fi
  git -C "${FF_SRC}" checkout -q FETCH_HEAD
fi

FF_BUILD="${BUILD}/ffmpeg"
rm -rf "${FF_BUILD}"
mkdir -p "${FF_BUILD}"
cd "${FF_BUILD}"

mapfile -t BASE_ARGS < <(configure_capto_args "${PREFIX}" "${TARGET}" "${CC}" "${CXX}" "${AR}" "${RANLIB}" | grep -v '^$' | grep -v '^#')

# Export AMF include path (FFmpeg looks for AMF/core/Factory.h with -I)
export CFLAGS="${CFLAGS:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib -static"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export PKG_CONFIG="pkg-config --static"

echo "==> configure"
# shellcheck disable=SC2068
"${FF_SRC}/configure" \
  "${BASE_ARGS[@]}" \
  --extra-libs="-lx264" \
  --enable-w32threads \
  --disable-pthreads \
  || {
    echo "configure failed; last config.log lines:" >&2
    tail -n 80 ffbuild/config.log 2>/dev/null || tail -n 80 config.log 2>/dev/null || true
    exit 1
  }

# Upstream attaches aom_film_grain.o to HEVC_SEI only; H264_SEI still calls it.
"${SCRIPT_DIR}/patch-ffmpeg-makefile.sh"

echo "==> make"
make -j"${jobs}"

mkdir -p "${OUT}"
cp -f ffmpeg.exe "${OUT}/ffmpeg.exe" 2>/dev/null || cp -f ffmpeg "${OUT}/ffmpeg.exe"
cp -f "${OUT}/ffmpeg.exe" "${OUT}/${TAURI_BIN_ALIAS}"

# Strip if available via zig/llvm
if command -v llvm-strip >/dev/null 2>&1; then
  llvm-strip "${OUT}/ffmpeg.exe" || true
elif [[ -x "${ZIG}" ]]; then
  "${ZIG}" objcopy --strip-all "${OUT}/ffmpeg.exe" "${OUT}/ffmpeg.exe.stripped" 2>/dev/null \
    && mv -f "${OUT}/ffmpeg.exe.stripped" "${OUT}/ffmpeg.exe" || true
fi

ls -lh "${OUT}/ffmpeg.exe"
echo "built ${OUT}/ffmpeg.exe"
