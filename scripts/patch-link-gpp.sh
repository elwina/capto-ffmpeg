#!/usr/bin/env bash
# After configure: use MinGW g++ as LD so static libvpl (C++) links cleanly.
# Zig compiles C; MinGW links C++ EH/stdlib for the VPL dispatcher hook.
set -euo pipefail
CFG="${1:-ffbuild/config.mak}"
[[ -f "${CFG}" ]] || { echo "missing ${CFG}" >&2; exit 1; }

GPP=""
for c in /mingw64/bin/g++.exe g++; do
  if command -v "${c}" >/dev/null 2>&1 || [[ -x "${c}" ]]; then
    GPP="$(command -v "${c}" 2>/dev/null || echo "${c}")"
    break
  fi
done
[[ -n "${GPP}" ]] || { echo "mingw g++ required to link libvpl" >&2; exit 1; }

# Strip CR first. With CRLF, a trailing `\r` stays in the value; worse, if the
# file is CR-joined, `[^ ]*` / `\S` can swallow the next assignment and produce
# linker garbage like `--as-neededLDEXEFLAGS=`.
perl -i -pe 's/\r$//' "${CFG}"

perl -i -pe "s|^LD=.*|LD=${GPP}|; s|^LDXX=.*|LDXX=${GPP}|" "${CFG}"
# Flags Zig/lld accept but MinGW ld rejects (one flag token; never cross lines)
perl -i -pe 's/ -Qunused-arguments//g; s/ -Wl,-z,noexecstack//g; s/ -Wl,-rpath-link=\S+//g' "${CFG}"
if ! grep -q 'static-libstdc++' "${CFG}"; then
  perl -i -pe 's|^(LDFLAGS=.*)|$1 -static-libgcc -static-libstdc++|' "${CFG}"
fi
echo "link via ${GPP}"
grep -E '^(LD|LDXX|LDFLAGS|LDEXEFLAGS)=' "${CFG}"
