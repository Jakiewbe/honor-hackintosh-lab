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

# The OGKM makefiles want GNU make 4. Homebrew needs a network, so when no gmake 4 is present build one
# from the tarball carried on the stick. Only if that tarball is missing fall back to the system make.
need_gmake=1
if command -v gmake >/dev/null && gmake --version 2>/dev/null | head -1 | grep -q 'GNU Make 4'; then
  need_gmake=0
fi
if [ "$need_gmake" = 1 ]; then
  tarball=""
  for base in "$HERE/g1-tools" "$HERE/../g1-tools" "$HOME/Desktop/HONOR-G1-FIRST-TOUCH/g1-tools" \
              /Volumes/*/g1-tools /Volumes/*/HONOR-G1-FIRST-TOUCH/g1-tools; do
    if [ -z "$tarball" ] && [ -f "$base/make-4.4.1.tar.gz" ]; then
      tarball="$base/make-4.4.1.tar.gz"
    fi
  done
  if [ -n "$tarball" ]; then
    echo "building GNU make 4.4.1 from $tarball (offline, about 1-2 min)"
    mkdir -p "$WORK/tools"
    rm -rf "$WORK/tools/make-4.4.1"
    tar -xzf "$tarball" -C "$WORK/tools" || { echo "STOP: cannot unpack $tarball"; exit 2; }
    (
      cd "$WORK/tools/make-4.4.1" &&
      ./configure --prefix="$WORK/tools/make" >"$WORK/tools/make-configure.log" 2>&1 &&
      make -j4 >"$WORK/tools/make-build.log" 2>&1 &&
      make install >>"$WORK/tools/make-build.log" 2>&1
    ) || { echo "STOP: building GNU make failed; see $WORK/tools/make-build.log"; exit 2; }
    # `make install` installs `make`; where the binary lands differs between releases, so find it.
    gbin=""
    for candidate in "$WORK/tools/make/bin/gmake" "$WORK/tools/make/bin/make" \
                     "$WORK/tools/make-4.4.1/make"; do
      if [ -z "$gbin" ] && [ -x "$candidate" ]; then gbin="$candidate"; fi
    done
    [ -n "$gbin" ] || { echo "STOP: GNU make built but no binary found"; exit 2; }
    mkdir -p "$WORK/bin"
    ln -sf "$gbin" "$WORK/bin/gmake"
    export PATH="$WORK/bin:$WORK/tools/make/bin:$PATH"
    echo "gmake: $("$gbin" --version | head -1)  ($gbin)"
  elif command -v make >/dev/null; then
    mkdir -p "$WORK/bin"
    ln -sf "$(command -v make)" "$WORK/bin/gmake"
    export PATH="$WORK/bin:$PATH"
    echo "WARN: no gmake 4 and no bundled source; using $(make --version | head -1) via a shim"
  else
    echo "STOP: need gmake 4 (brew install make) or the bundled make-4.4.1.tar.gz"; exit 2
  fi
fi


fetch() {
  # bash 3.2 declares every name in one `local` before assigning any of them, so a later assignment in
  # the same statement cannot read an earlier one under `set -u`. Keep them separate.
  local name="$1"
  local url="$2"
  local pin="$3"
  local dir="${WORK}/${name}"
  local pre=""
  case "$name" in
    nm) pre="$NM_SRC" ;;
    nv) pre="$NV_SRC" ;;
  esac
  if [[ -n "$pre" && -d "$pre/.git" ]]; then
    [[ "$(git -C "$pre" rev-parse HEAD)" == "$pin" ]] || { echo "STOP: $pre is not at $pin"; exit 2; }
    # Untracked files are ignored on purpose: Finder and Spotlight drop .DS_Store into every folder on
    # the stick, which would otherwise look like local changes and send the build to the network.
    if [[ -z "$(git -C "$pre" status --porcelain --untracked-files=no)" ]]; then
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
