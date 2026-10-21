#!/bin/bash
# Reproduce, on your own Mac, exactly what the package workflow does on the runner, then run the
# loader dry run (kextutil -n) on the three bundles. Nothing is installed, loaded or executed.
#
# Requirements: Xcode 16.4 with macOS 15.5 SDK, python3, gmake (brew install make), git.
# Time: the OGKM object build is the slow part (roughly 20-40 min on a laptop).
#
# Usage:  bash device-kextutil.sh [repo-root] [work-dir]
set -euo pipefail

REPO=${1:-$(cd "$(dirname "$0")/../.." && pwd)}
WORK=${2:-$HOME/Desktop/g1-kextutil}
NM_PIN=272ccd9da04ff5de95c2791b902fe17a3fa77ce7
NV_PIN=e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb

mkdir -p "$WORK"
echo "repo=$REPO work=$WORK"
sw_vers | tee "$WORK/sw_vers.txt"
xcodebuild -version | tee -a "$WORK/sw_vers.txt"
[[ "$(xcrun --show-sdk-version)" == 15.5 ]] || { echo "STOP: need SDK 15.5"; exit 2; }
command -v gmake >/dev/null || { echo "STOP: install gmake (brew install make)"; exit 2; }

fetch() {
  local name=$1 url=$2 pin=$3 dir=$WORK/$name
  if [[ ! -d "$dir/.git" ]]; then
    git -c core.autocrlf=false init -q "$dir"
    git -C "$dir" config core.autocrlf false
    git -C "$dir" remote add origin "$url"
    git -C "$dir" fetch --no-tags --depth 1 origin "$pin"
    git -C "$dir" checkout --detach -q FETCH_HEAD
  fi
  [[ "$(git -C "$dir" rev-parse HEAD)" == "$pin" ]] || { echo "STOP: $name at wrong commit"; exit 2; }
}

fetch nm https://github.com/nullmoth/nvidia-macos-driver.git "$NM_PIN"
fetch nv https://github.com/NVIDIA/open-gpu-kernel-modules.git "$NV_PIN"

echo "== internal link (applies the converged patch, builds RM and links the 12 TUs)"
python3 "$REPO/scripts/g1/stock_v243_internal_link.py" \
  --nm "$WORK/nm" --nv "$WORK/nv" \
  --assets "$REPO/research/stock-v243-once-20261021" \
  --out "$WORK/internal-text" --work "$WORK/internal-products"

echo "== package audit (NVKMS pairing, NVRMFB/NVAccel, io_fam 15 layout, imports, kextutil -n)"
python3 "$REPO/scripts/g1/stock_v243_package.py" \
  --internal-text "$WORK/internal-text" \
  --work "$WORK/internal-products" --out "$WORK/package-text"

echo "== loader dry run on the three produced bundles (no load)"
for kext in NVRM NVRMFB NVAccel; do
  bundle="$WORK/internal-products/package-products/$kext.kext"
  echo "--- $kext"
  xcrun kextutil -n "$bundle" 2>&1 | tee "$WORK/kextutil-$kext.txt"
  echo "exit=${PIPESTATUS[0]}" | tee -a "$WORK/kextutil-$kext.txt"
done

echo
echo "Send back these files from $WORK:"
ls -1 "$WORK"/package-text/*.json "$WORK"/package-text/*.txt "$WORK"/kextutil-*.txt 2>/dev/null | sed 's/^/  /'
