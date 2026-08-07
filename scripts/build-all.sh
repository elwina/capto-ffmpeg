#!/usr/bin/env bash
# Full local pipeline: deps -> ffmpeg -> audit -> smoke
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/build-deps.sh"
"${SCRIPT_DIR}/build-windows.sh"
"${SCRIPT_DIR}/audit-dlls.sh"
"${SCRIPT_DIR}/smoke.sh"

echo "ALL GREEN"
