#!/usr/bin/env bash
# Shared paths + load versions.env. Source from other scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/versions.env"

export ROOT
export DEPS_SRC="${ROOT}/deps-src"
export PREFIX="${ROOT}/prefix"
export BUILD="${ROOT}/build"
export OUT="${ROOT}/out"
export PATH_ZIG="${ROOT}/.tools/zig-${ZIG_VERSION}"

mkdir -p "${DEPS_SRC}" "${PREFIX}" "${BUILD}" "${OUT}" "${ROOT}/.tools"

host_os="$(uname -s)"
host_arch="$(uname -m)"
case "${host_os}" in
  Linux)
    case "${host_arch}" in
      x86_64) ZIG_ARCHIVE="zig-x86_64-linux-${ZIG_VERSION}.tar.xz" ;;
      aarch64) ZIG_ARCHIVE="zig-aarch64-linux-${ZIG_VERSION}.tar.xz" ;;
      *) echo "unsupported arch: ${host_arch}" >&2; exit 1 ;;
    esac
    ;;
  Darwin)
    case "${host_arch}" in
      x86_64) ZIG_ARCHIVE="zig-x86_64-macos-${ZIG_VERSION}.tar.xz" ;;
      arm64) ZIG_ARCHIVE="zig-aarch64-macos-${ZIG_VERSION}.tar.xz" ;;
      *) echo "unsupported arch: ${host_arch}" >&2; exit 1 ;;
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*)
    ZIG_ARCHIVE="zig-x86_64-windows-${ZIG_VERSION}.zip"
    ;;
  *)
    echo "unsupported host OS: ${host_os}" >&2
    exit 1
    ;;
esac

export ZIG_ARCHIVE
export ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_ARCHIVE}"
