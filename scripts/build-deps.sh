#!/usr/bin/env bash
# Build static deps into $PREFIX (x264 + NVENC/AMF headers). No FreeType.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/zig-env.sh"

jobs="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

fetch_git() {
  local url="$1" dest="$2" ref="$3"
  if [[ -d "${dest}/.git" ]]; then
    git -C "${dest}" fetch --depth 1 origin "${ref}" || git -C "${dest}" fetch origin "${ref}"
    git -C "${dest}" checkout -q FETCH_HEAD 2>/dev/null || git -C "${dest}" checkout -q "${ref}"
  else
    rm -rf "${dest}"
    git clone --depth 1 --branch "${ref}" "${url}" "${dest}" \
      || { git clone "${url}" "${dest}"; git -C "${dest}" checkout "${ref}"; }
  fi
}

echo "==> ffnvcodec-headers ${FFNVCODEC_TAG}"
fetch_git https://github.com/FFmpeg/nv-codec-headers.git \
  "${DEPS_SRC}/nv-codec-headers" "${FFNVCODEC_TAG}"
make -C "${DEPS_SRC}/nv-codec-headers" PREFIX="${PREFIX}" install

echo "==> AMF headers ${AMF_TAG}"
fetch_git https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git \
  "${DEPS_SRC}/AMF" "${AMF_TAG}"
mkdir -p "${PREFIX}/include/AMF"
# FFmpeg expects AMF headers under include/AMF/... matching upstream layout
rsync -a --delete "${DEPS_SRC}/AMF/amf/public/include/" "${PREFIX}/include/AMF/" 2>/dev/null \
  || cp -a "${DEPS_SRC}/AMF/amf/public/include/." "${PREFIX}/include/AMF/"

echo "==> x264 (${X264_REF})"
fetch_git https://code.videolan.org/videolan/x264.git \
  "${DEPS_SRC}/x264" "${X264_REF}"

# x264 stable branch tip; if branch clone failed above, already handled
rm -rf "${BUILD}/x264"
mkdir -p "${BUILD}/x264"
cd "${DEPS_SRC}/x264"

# Cross-compile static lib only. zig as CC.
# Cross-compile static lib only. Pass toolchain via env (x264 ignores CC= argv).
CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" ./configure \
  --prefix="${PREFIX}" \
  --host=x86_64-w64-mingw32 \
  --enable-static \
  --disable-cli \
  --disable-opencl \
  --extra-cflags="-O2"

make -j"${jobs}"
make install

# Drop any import libs that could confuse pkg-config into dynamic linking
find "${PREFIX}" -name '*.dll' -delete
find "${PREFIX}" -name '*.dll.a' -delete

echo "deps installed -> ${PREFIX}"
ls -la "${PREFIX}/lib" || true
ls -la "${PREFIX}/lib/pkgconfig" || true
