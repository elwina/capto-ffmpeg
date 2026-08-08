#!/usr/bin/env bash
# Shared paths + load versions.env. Source from other scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/versions.env"

# Allow CI / local overrides before deriving ARCH.
if [[ -n "${TARGET_OVERRIDE:-}" ]]; then
  TARGET="${TARGET_OVERRIDE}"
fi
if [[ -n "${ARCH_OVERRIDE:-}" ]]; then
  case "${ARCH_OVERRIDE}" in
    x86_64|amd64|x64) TARGET=x86_64-windows-gnu ;;
    aarch64|arm64) TARGET=aarch64-windows-gnu ;;
    *) echo "unsupported ARCH_OVERRIDE=${ARCH_OVERRIDE}" >&2; exit 1 ;;
  esac
fi

case "${TARGET}" in
  x86_64-*) ARCH=x86_64 ;;
  aarch64-*|arm64-*) ARCH=aarch64 ;;
  *)
    echo "unsupported TARGET=${TARGET}" >&2
    exit 1
    ;;
esac

# Intel QSV / libvpl only on x86_64 by default.
if [[ -z "${ENABLE_LIBVPL:-}" ]]; then
  if [[ "${ARCH}" == "x86_64" ]]; then
    ENABLE_LIBVPL=1
  else
    ENABLE_LIBVPL=0
  fi
fi

RELEASE_NAME="ffmpeg-windows-${ARCH}.exe"

export ROOT
export ARCH
export TARGET
export ENABLE_LIBVPL
export RELEASE_NAME
export DEPS_SRC="${ROOT}/deps-src"
# Per-arch trees so x86_64 and aarch64 can coexist on one machine.
export PREFIX="${ROOT}/prefix-${ARCH}"
export BUILD="${ROOT}/build-${ARCH}"
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
    case "${host_arch}" in
      aarch64|arm64) ZIG_ARCHIVE="zig-aarch64-windows-${ZIG_VERSION}.zip" ;;
      *) ZIG_ARCHIVE="zig-x86_64-windows-${ZIG_VERSION}.zip" ;;
    esac
    ;;
  *)
    echo "unsupported host OS: ${host_os}" >&2
    exit 1
    ;;
esac

export ZIG_ARCHIVE
export ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_ARCHIVE}"
