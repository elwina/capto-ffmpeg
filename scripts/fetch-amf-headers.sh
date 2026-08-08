#!/usr/bin/env bash
# Fetch only AMF public headers for a tag via GitHub API + jsDelivr (avoids huge full-repo clone).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/versions.env"
# shellcheck disable=SC1091
source "${ROOT}/scripts/common.sh"

TAG="${AMF_TAG}"
DEST="${PREFIX}/include/AMF"
TMP="${DEPS_SRC}/amf-headers-list.json"

PYTHON_BIN=""
for c in python3 python \
  "/c/Users/elwin/.local/bin/python3.exe" \
  "/c/Users/elwin/.local/bin/python.exe"; do
  if command -v "${c}" >/dev/null 2>&1 || [[ -x "${c}" ]]; then
    PYTHON_BIN="$(command -v "${c}" 2>/dev/null || echo "${c}")"
    break
  fi
done
[[ -n "${PYTHON_BIN}" ]] || { echo "python required to fetch AMF headers" >&2; exit 1; }

echo "==> AMF headers ${TAG} (API + jsDelivr) via ${PYTHON_BIN}"
mkdir -p "${DEPS_SRC}"
curl -fsSL --max-time 60 \
  "https://api.github.com/repos/GPUOpen-LibrariesAndSDKs/AMF/git/trees/${TAG}?recursive=1" \
  -o "${TMP}"

"${PYTHON_BIN}" - <<'PY' "${TMP}" "${DEST}" "${TAG}"
import json, os, sys, urllib.request
tree_path, dest, tag = sys.argv[1], sys.argv[2], sys.argv[3]
prefix = "amf/public/include/"
data = json.load(open(tree_path, encoding="utf-8"))
paths = [t["path"] for t in data.get("tree", []) if t.get("type") == "blob" and t["path"].startswith(prefix)]
if not paths:
    raise SystemExit("no AMF include blobs found")
# wipe stale headers from older AMF pins
if os.path.isdir(dest):
    import shutil
    shutil.rmtree(dest)
os.makedirs(dest, exist_ok=True)
base = f"https://cdn.jsdelivr.net/gh/GPUOpen-LibrariesAndSDKs/AMF@{tag}/"
for i, path in enumerate(paths, 1):
    rel = path[len(prefix):]
    out = os.path.join(dest, rel.replace("/", os.sep))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    url = base + path
    print(f"[{i}/{len(paths)}] {rel}")
    urllib.request.urlretrieve(url, out)
print(f"installed {len(paths)} headers -> {dest}")
PY

grep AMF_VERSION_ "${DEST}/core/Version.h" | head -5
