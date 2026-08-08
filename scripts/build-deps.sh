#!/usr/bin/env bash
# Build static deps into $PREFIX:
#   x264 (static) + NVENC/AMF headers + (x86_64) Intel VPL dispatcher.
# Vendor GPU runtimes are NOT shipped — LoadLibrary at encode time.
# No FreeType / no libx265.
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

echo "==> arch=${ARCH} target=${TARGET} enable_libvpl=${ENABLE_LIBVPL}"
echo "==> ffnvcodec-headers ${FFNVCODEC_TAG}"
fetch_git https://github.com/FFmpeg/nv-codec-headers.git \
  "${DEPS_SRC}/nv-codec-headers" "${FFNVCODEC_TAG}"
make -C "${DEPS_SRC}/nv-codec-headers" PREFIX="${PREFIX}" install

echo "==> AMF headers ${AMF_TAG}"
"${SCRIPT_DIR}/fetch-amf-headers.sh"

if [[ "${ENABLE_LIBVPL}" == "1" ]]; then
  echo "==> libvpl dispatcher ${LIBVPL_TAG} (static; runtime loads Intel GPU impl)"
  fetch_git https://github.com/intel/libvpl.git \
    "${DEPS_SRC}/libvpl" "${LIBVPL_TAG}"
  rm -rf "${BUILD}/libvpl"
  CMAKE_BIN=""
  for c in /mingw64/bin/cmake.exe /clangarm64/bin/cmake.exe cmake; do
    if command -v "${c}" >/dev/null 2>&1 || [[ -x "${c}" ]]; then
      CMAKE_BIN="${c}"
      break
    fi
  done
  [[ -n "${CMAKE_BIN}" ]] || { echo "cmake required to build libvpl" >&2; exit 1; }

  VPL_CC="${CC}"
  VPL_CXX="${CXX}"
  if [[ -x /mingw64/bin/gcc.exe && -x /mingw64/bin/g++.exe ]]; then
    VPL_CC=/mingw64/bin/gcc.exe
    VPL_CXX=/mingw64/bin/g++.exe
    export PATH="/mingw64/bin:${PATH}"
  fi

  "${CMAKE_BIN}" -S "${DEPS_SRC}/libvpl" -B "${BUILD}/libvpl" \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_C_COMPILER="${VPL_CC}" \
    -DCMAKE_CXX_COMPILER="${VPL_CXX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_TOOLS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DINSTALL_DEV=ON

  "${CMAKE_BIN}" --build "${BUILD}/libvpl" --parallel "${jobs}"
  "${CMAKE_BIN}" --install "${BUILD}/libvpl"

  if [[ ! -f "${PREFIX}/lib/pkgconfig/vpl.pc" ]]; then
    echo "missing vpl.pc after libvpl install" >&2
    find "${PREFIX}" -name '*.pc' -o -name 'libvpl*' | head -40 >&2
    exit 1
  fi
  cat "${PREFIX}/lib/pkgconfig/vpl.pc"
else
  echo "==> skip libvpl (ENABLE_LIBVPL=${ENABLE_LIBVPL}; QSV is x86_64/Intel-oriented)"
fi

echo "==> x264 (${X264_REF})"
fetch_git https://code.videolan.org/videolan/x264.git \
  "${DEPS_SRC}/x264" "${X264_REF}"

rm -rf "${BUILD}/x264"
mkdir -p "${BUILD}/x264"
cd "${DEPS_SRC}/x264"

x264_host="x86_64-w64-mingw32"
if [[ "${ARCH}" == "aarch64" ]]; then
  x264_host="aarch64-w64-mingw32"
fi

CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" ./configure \
  --prefix="${PREFIX}" \
  --host="${x264_host}" \
  --enable-static \
  --disable-cli \
  --disable-opencl \
  --extra-cflags="-O2"

make -j"${jobs}"
make install

find "${PREFIX}" -name '*.dll' -delete
find "${PREFIX}" -name '*.dll.a' -delete

echo "deps installed -> ${PREFIX}"
ls -la "${PREFIX}/lib" || true
ls -la "${PREFIX}/lib/pkgconfig" || true
