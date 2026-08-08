#!/usr/bin/env bash
# Ensure pinned Zig is present and export CC/CXX/AR for Windows builds.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

# Prefer an already-installed Zig matching versions.env (e.g. winget).
find_system_zig() {
  local candidate got
  for candidate in zig zig.exe \
    "/c/Users/${USER:-}/AppData/Local/Microsoft/WinGet/Links/zig.exe" \
    "/c/Program Files/Zig/zig.exe"; do
    if command -v "${candidate}" >/dev/null 2>&1 || [[ -x "${candidate}" ]]; then
      if command -v "${candidate}" >/dev/null 2>&1; then
        candidate="$(command -v "${candidate}")"
      fi
      got="$("${candidate}" version 2>/dev/null | head -n1 | tr -d '\r')"
      if [[ "${got}" == "${ZIG_VERSION}" ]]; then
        echo "${candidate}"
        return 0
      fi
    fi
  done
  return 1
}

ensure_zig() {
  local sys
  if sys="$(find_system_zig)"; then
    export ZIG="${sys}"
    echo "using system zig ${ZIG_VERSION}: ${ZIG}"
    return 0
  fi

  local zig_bin="${PATH_ZIG}/zig"
  local zig_exe="${PATH_ZIG}/zig.exe"
  if [[ -x "${zig_bin}" || -x "${zig_exe}" ]]; then
    local bin="${zig_bin}"
    [[ -x "${bin}" ]] || bin="${zig_exe}"
    local got
    got="$("${bin}" version | head -n1 | tr -d '\r')"
    if [[ "${got}" == "${ZIG_VERSION}" ]]; then
      export ZIG="${bin}"
      echo "zig ${got} ok (${PATH_ZIG})"
      return 0
    fi
    rm -rf "${PATH_ZIG}"
  fi

  local archive="${ROOT}/.tools/${ZIG_ARCHIVE}"
  echo "downloading ${ZIG_URL}"
  curl -fsSL "${ZIG_URL}" -o "${archive}"
  mkdir -p "${PATH_ZIG}"

  case "${ZIG_ARCHIVE}" in
    *.tar.xz)
      tar -xJf "${archive}" -C "${ROOT}/.tools"
      local extracted
      extracted="$(find "${ROOT}/.tools" -maxdepth 1 -type d -name "zig-*-${ZIG_VERSION}" | head -n1)"
      [[ -n "${extracted}" ]] || { echo "zig extract failed" >&2; exit 1; }
      if [[ "${extracted}" != "${PATH_ZIG}" ]]; then
        rm -rf "${PATH_ZIG}"
        mv "${extracted}" "${PATH_ZIG}"
      fi
      ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "${archive}" -d "${ROOT}/.tools"
      else
        powershell.exe -NoProfile -Command "Expand-Archive -Force '${archive}' '${ROOT}/.tools'"
      fi
      local extracted
      extracted="$(find "${ROOT}/.tools" -maxdepth 1 -type d -name "zig-*-${ZIG_VERSION}" | head -n1)"
      [[ -n "${extracted}" ]] || { echo "zig extract failed" >&2; exit 1; }
      if [[ "${extracted}" != "${PATH_ZIG}" ]]; then
        rm -rf "${PATH_ZIG}"
        mv "${extracted}" "${PATH_ZIG}"
      fi
      ;;
  esac

  if [[ -x "${PATH_ZIG}/zig" ]]; then
    export ZIG="${PATH_ZIG}/zig"
  elif [[ -x "${PATH_ZIG}/zig.exe" ]]; then
    export ZIG="${PATH_ZIG}/zig.exe"
  else
    echo "zig binary missing after extract" >&2
    exit 1
  fi
  echo "installed zig $("${ZIG}" version)"
}

ensure_zig

# Wrappers avoid spaces in --cc= which break FFmpeg/x264 configure.
WRAP="${ROOT}/.tools/bin"
mkdir -p "${WRAP}"
cat > "${WRAP}/zig-cc" <<EOF
#!/usr/bin/env bash
exec "$(cygpath -u "${ZIG}" 2>/dev/null || echo "${ZIG}")" cc -target ${TARGET} "\$@"
EOF
cat > "${WRAP}/zig-c++" <<EOF
#!/usr/bin/env bash
exec "$(cygpath -u "${ZIG}" 2>/dev/null || echo "${ZIG}")" c++ -target ${TARGET} "\$@"
EOF
cat > "${WRAP}/zig-ar" <<EOF
#!/usr/bin/env bash
exec "$(cygpath -u "${ZIG}" 2>/dev/null || echo "${ZIG}")" ar "\$@"
EOF
cat > "${WRAP}/zig-ranlib" <<EOF
#!/usr/bin/env bash
exec "$(cygpath -u "${ZIG}" 2>/dev/null || echo "${ZIG}")" ranlib "\$@"
EOF
chmod +x "${WRAP}/zig-cc" "${WRAP}/zig-c++" "${WRAP}/zig-ar" "${WRAP}/zig-ranlib"

# If ZIG path has spaces or Windows form, rewrite wrappers with a safer path
ZIG_U="$(cygpath -u "${ZIG}" 2>/dev/null || echo "${ZIG}")"
# MinGW C++ EH when linking libvpl (built with g++) into Zig/lld binaries.
GCCLIB="$(echo /mingw64/lib/gcc/x86_64-w64-mingw32/*/libgcc.a | awk '{print $1}')"
GCCEH="$(echo /mingw64/lib/gcc/x86_64-w64-mingw32/*/libgcc_eh.a | awk '{print $1}')"
cat > "${WRAP}/zig-cc" <<EOF
#!/usr/bin/env bash
# Rewrite -lstdc++ -> MinGW static libstdc++ + libgcc_eh only when linking.
args=()
linking=1
for a in "\$@"; do
  case "\$a" in
    -c|-E|-S|-emit-ast) linking=0 ;;
  esac
done
for a in "\$@"; do
  if [[ "\$linking" -eq 1 && "\$a" == "-lstdc++" ]]; then
    args+=(/mingw64/lib/libstdc++.a "${GCCEH}" "${GCCLIB}")
  else
    args+=("\$a")
  fi
done
exec "${ZIG_U}" cc -target ${TARGET} "\${args[@]}"
EOF
cat > "${WRAP}/zig-c++" <<EOF
#!/usr/bin/env bash
args=()
linking=1
for a in "\$@"; do
  case "\$a" in
    -c|-E|-S|-emit-ast) linking=0 ;;
  esac
done
for a in "\$@"; do
  if [[ "\$linking" -eq 1 && "\$a" == "-lstdc++" ]]; then
    args+=(/mingw64/lib/libstdc++.a "${GCCEH}" "${GCCLIB}")
  else
    args+=("\$a")
  fi
done
exec "${ZIG_U}" c++ -target ${TARGET} "\${args[@]}"
EOF
cat > "${WRAP}/zig-ar" <<EOF
#!/usr/bin/env bash
exec "${ZIG_U}" ar "\$@"
EOF
cat > "${WRAP}/zig-ranlib" <<EOF
#!/usr/bin/env bash
exec "${ZIG_U}" ranlib "\$@"
EOF
chmod +x "${WRAP}/zig-cc" "${WRAP}/zig-c++" "${WRAP}/zig-ar" "${WRAP}/zig-ranlib"
# windres (FFmpeg Windows resource) shells out to `gcc` for preprocessing
ln -sfn "${WRAP}/zig-cc" "${WRAP}/gcc"
ln -sfn "${WRAP}/zig-c++" "${WRAP}/g++"

export ZIG
export TARGET
export CC="${WRAP}/zig-cc"
export CXX="${WRAP}/zig-c++"
export AR="${WRAP}/zig-ar"
export RANLIB="${WRAP}/zig-ranlib"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="${PREFIX}/lib/pkgconfig"
export PATH="${WRAP}:$(dirname "${ZIG_U}"):${PATH}"

echo "ZIG=${ZIG}"
echo "CC=${CC}"
echo "TARGET=${TARGET}"
echo "PREFIX=${PREFIX}"
