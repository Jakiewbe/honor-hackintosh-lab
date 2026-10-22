#!/bin/bash
# Direct entry uses the same mandatory Python preflight as the menu. Offline only.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
REPO="${1:-${REPO:-$(cd "${HERE}/../.." && pwd -P)}}"
WORK="${2:-${WORK:-${HOME}/Desktop/g1-kextutil}}"
PYTHON="${PYTHON:-python3}"
exec "$PYTHON" "${REPO}/scripts/g1/offline_build.py" build --repo "${REPO}" --work "${WORK}"
