#!/usr/bin/env bash
# Fail if ffmpeg.exe imports non-allowlisted DLLs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

EXE="${1:-${OUT}/ffmpeg.exe}"
if [[ ! -f "${EXE}" ]]; then
  echo "missing ${EXE}" >&2
  exit 1
fi

# Windows system DLLs commonly referenced by a static mingw ffmpeg + dshow/ole.
# api-ms-win-* / ext-ms-* are UCRT/API-set forwarders shipped with Windows 10+.
ALLOW_REGEX='^(KERNEL32|kernel32|USER32|user32|GDI32|gdi32|ADVAPI32|advapi32|SHELL32|shell32|OLE32|ole32|OLEAUT32|oleaut32|WS2_32|ws2_32|bcrypt|BCRYPT|ntdll|NTDLL|msvcrt|MSVCRT|ucrtbase|UCRTBASE|IMM32|imm32|COMDLG32|comdlg32|COMCTL32|comctl32|WINMM|winmm|SETUPAPI|setupapi|CFGMGR32|cfgmgr32|SHLWAPI|shlwapi|PROPSYS|propsys|dwmapi|DWMAPI|DXGI|dxgi|d3d11|D3D11|MFPLAT|mfplat|MFREADWRITE|mfreadwrite|api-ms-win-.*|ext-ms-.*|mf)\.dll$'

dump_dlls() {
  local exe="$1"
  if command -v x86_64-w64-mingw32-objdump >/dev/null 2>&1; then
    x86_64-w64-mingw32-objdump -p "${exe}"
  elif command -v llvm-objdump >/dev/null 2>&1; then
    llvm-objdump -p "${exe}"
  elif command -v objdump >/dev/null 2>&1; then
    objdump -p "${exe}"
  else
    echo "need objdump or llvm-objdump" >&2
    exit 1
  fi
}

mapfile -t dlls < <(dump_dlls "${EXE}" | sed -n 's/.*DLL Name: *//p' | tr -d '\r' | sort -u)
if [[ ${#dlls[@]} -eq 0 ]]; then
  echo "warning: no DLL imports parsed; dumping raw headers" >&2
  dump_dlls "${EXE}" | head -n 80 >&2
  exit 1
fi

bad=0
echo "DLL imports for ${EXE}:"
for d in "${dlls[@]}"; do
  base="$(basename "${d}")"
  if echo "${base}" | grep -Eiq "${ALLOW_REGEX}"; then
    echo "  OK  ${base}"
  else
    echo "  BAD ${base}" >&2
    bad=1
  fi
done

if [[ "${bad}" -ne 0 ]]; then
  echo "DLL audit failed — unexpected runtime dependency" >&2
  exit 1
fi
echo "DLL audit passed"
