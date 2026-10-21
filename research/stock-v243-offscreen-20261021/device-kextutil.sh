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
# Command Line Tools alone provide clang, make, git, python3 and the SDK, but not xcodebuild. Do not let
# its absence abort the build on a CLT-only machine.
{ xcodebuild -version 2>/dev/null || echo "xcodebuild: absent (Command Line Tools only)"; } | tee -a "$WORK/sw_vers.txt"
SDK=$(xcrun --show-sdk-version)
# The compile flags set -mmacosx-version-min=15.5, so any SDK at or above 15.5 works; Xcode 16.4's 15.5
# is simply the version the CI evidence used. Only an older SDK is a hard stop.
echo "SDK: $SDK"
case "$SDK" in
  15.[5-9]*|15.[5-9]|1[6-9].*|2[0-9].*) : ;;
  *) echo "STOP: need SDK >= 15.5 (found $SDK); select Xcode 16.4 with xcode-select"; exit 2 ;;
esac
# Offline mode: the two pinned source trees can be carried on the install stick instead of fetched.
NM_SRC=${NM_SRC:-}
NV_SRC=${NV_SRC:-}
HERE=$(cd "$(dirname "$0")" && pwd)
for base in "$HERE/g1-src" "$HERE/../g1-src" "$HOME/Desktop/HONOR-G1-FIRST-TOUCH/g1-src" \
            /Volumes/*/g1-src /Volumes/*/HONOR-G1-FIRST-TOUCH/g1-src; do
  if [ -d "$base/nm/.git" ] && [ -z "$NM_SRC" ]; then NM_SRC="$base/nm"; fi
  if [ -d "$base/nv/.git" ] && [ -z "$NV_SRC" ]; then NV_SRC="$base/nv"; fi
done
[ -n "$NM_SRC" ] && echo "pre-staged NullMoth: $NM_SRC"
[ -n "$NV_SRC" ] && echo "pre-staged OGKM:     $NV_SRC"

# gmake is only needed because the OGKM makefiles use GNU make 4 syntax. Without network, fall back to
# the system make and say so; a syntax error later will name the reason.
if ! command -v gmake >/dev/null; then
  if command -v make >/dev/null; then
    mkdir -p "$WORK/bin"
    ln -sf "$(command -v make)" "$WORK/bin/gmake"
    export PATH="$WORK/bin:$PATH"
    echo "WARN: gmake missing, using $(make --version | head -1) via a shim"
  else
    echo "STOP: need gmake (brew install make) or make"; exit 2
  fi
fi

fetch() {
  local name=$1 url=$2 pin=$3 dir=$WORK/$name pre=""
  case "$name" in
    nm) pre="$NM_SRC" ;;
    nv) pre="$NV_SRC" ;;
  esac
  if [[ -n "$pre" && -d "$pre/.git" ]]; then
    [[ "$(git -C "$pre" rev-parse HEAD)" == "$pin" ]] || { echo "STOP: $pre is not at $pin"; exit 2; }
    if [[ -z "$(git -C "$pre" status --porcelain --untracked-files=all)" ]]; then
      rm -rf "$dir"
      mkdir -p "$(dirname "$dir")"
      cp -R "$pre" "$dir"
      echo "using pre-staged $name from $pre"
      [[ "$(git -C "$dir" rev-parse HEAD)" == "$pin" ]] || { echo "STOP: copy of $name is at the wrong commit"; exit 2; }
      return 0
    fi
    echo "WARN: $pre has local changes; fetching $name from the network instead"
  fi
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
