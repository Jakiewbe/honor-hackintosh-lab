#!/bin/bash
# Offline compile/link only. Bash 3.2 compatible. Installation is disabled.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
if [ -z "${REPO:-}" ]; then
  for candidate in "${HERE}/../.." "${HERE}/g1-repo" "${HERE}/../g1-repo"; do
    if [ -d "${candidate}/.git" ]; then REPO="$candidate"; break; fi
  done
fi
[ -n "${REPO:-}" ] || { echo 'STOP: set REPO to the local checkout; no clone attempted'; exit 2; }
for base in "${HERE}/g1-src" "${HERE}/../g1-src"; do
  if [ -z "${NM_SRC:-}" ] && [ -d "$base/nm/.git" ]; then export NM_SRC="$base/nm"; fi
  if [ -z "${NV_SRC:-}" ] && [ -d "$base/nv/.git" ]; then export NV_SRC="$base/nv"; fi
done
if [ -z "${G1_TOOLS:-}" ]; then
  for base in "${HERE}/g1-tools" "${HERE}/../g1-tools"; do
    if [ -d "$base" ]; then export G1_TOOLS="$base"; break; fi
  done
fi
action="${1:-}"
if [ -z "$action" ]; then
  printf '0) offline preflight
1) system version (read only)
2) compile/link (always reruns preflight)
q) quit
Install/rollback are disabled: LOAD NO-GO.
'
  read -r -p 'choice: ' action || exit 2
fi
case "$action" in
  0|preflight) action=preflight ;;
  2|build) action=build ;;
  1) sw_vers; exit $? ;;
  q|Q) exit 0 ;;
  *) echo 'STOP: installation, backup-as-recovery, verify-load and rollback are disabled (LOAD NO-GO)'; exit 42 ;;
esac
PYTHON="${PYTHON:-python3}"
exec "$PYTHON" "${REPO}/scripts/g1/offline_build.py" "$action" --repo "${REPO}" --work "${WORK:-${HOME}/Desktop/g1-kextutil}"
