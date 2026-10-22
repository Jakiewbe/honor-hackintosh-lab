#!/bin/bash
# HONOR G1 / RTX 2050 first-touch helper for macOS.
# Double-click in Finder, or run: bash g1-first-touch.command
#
# Menu:
#   1 check environment (read only)
#   2 build the candidate (20-40 min, needs Xcode 16.4 / SDK 15.5 / python3 / gmake)
#   3 back up the current system (read only)
#   4 install the candidate with -nvrmnogo (asks for YES, uses sudo)
#   5 verify after reboot (read only)
#   6 roll back
#
# It never runs nvrmctl go, never runs Metal, and never touches Windows/EFI/BIOS or other SIP settings.

set -uo pipefail

REPORT_DIR="${HOME}/Desktop/g1-first-touch"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="${REPORT_DIR}/report-${STAMP}.txt"
REPO="${REPO:-}"
WORK="${WORK:-${HOME}/Desktop/g1-kextutil}"
CAND="${CAND:-${WORK}/internal-products/package-products}"
BACKUP="${REPORT_DIR}"

mkdir -p "${REPORT_DIR}"
exec > >(tee -a "${REPORT}") 2>&1

say()  { printf '\n== %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; }
die()  { printf 'STOP: %s\n' "$*"; exit 1; }
ask()  { local a; read -r -p "$1 " a; printf '%s' "$a"; }

say "HONOR G1 first-touch  $(date)"
printf 'report: %s\n' "${REPORT}"

if [ "$(uname -s)" != "Darwin" ]; then
  die "this script only runs on macOS (current: $(uname -s))"
fi

find_repo() {
  if [ -n "${REPO}" ] && [ -d "${REPO}/.git" ]; then
    printf '%s\n' "${REPO}"
    return 0
  fi
  local here candidate
  here="$(cd "$(dirname "$0")" && pwd)"
  # The repository can travel on the same stick as this script: g1-repo next to it, or one level up.
  for candidate in \
      "${here}/g1-repo" \
      "${here}/../g1-repo" \
      "${HOME}/honor-hackintosh-lab" \
      "${HOME}/Desktop/honor-hackintosh-lab" \
      "${HOME}/Documents/honor-hackintosh-lab" \
      "/Volumes/macos/honor-hackintosh-lab" \
      "${HOME}/Projects/honor-hackintosh-lab"; do
    if [ -d "${candidate}/.git" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

ensure_repo() {
  local found
  if found="$(find_repo)"; then
    REPO="${found}"
    printf 'repo: %s\n' "${REPO}"
  else
    warn "repository not found in the usual places"
    printf 'clone it now into %s ? [y/N] ' "${HOME}/honor-hackintosh-lab"
    if [ "$(ask '')" = "y" ]; then
      git clone https://github.com/Jakiewbe/honor-hackintosh-lab.git \
        "${HOME}/honor-hackintosh-lab" || die "clone failed"
      REPO="${HOME}/honor-hackintosh-lab"
    else
      die "set REPO=/path/to/honor-hackintosh-lab and run again"
    fi
  fi
  printf 'repo HEAD: %s\n' "$(git -C "${REPO}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
}

check_env() {
  say "environment"
  sw_vers
  printf '\n-- SIP\n'
  csrutil status || warn "cannot read SIP status"
  printf '\n-- loaded kexts (NVRM/NVAccel/NVRMFB)\n'
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' || echo "(none loaded)"
  printf '\n-- /Library/Extensions\n'
  ls -1 /Library/Extensions 2>/dev/null | head -20
  printf '\n-- candidate\n'
  if [ -d "${CAND}/NVRM.kext" ]; then echo "present: ${CAND}/NVRM.kext"; else echo "absent: ${CAND}/NVRM.kext"; fi
  printf '\n-- volumes\n'
  ls -1 /Volumes
  printf '\n-- boot-args\n'
  nvram boot-args 2>/dev/null || echo "(none)"
  printf '\n-- toolchain\n'
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "no developer tools at all (xcode-select has no path). The build needs Command Line Tools:"
    echo "   offline: install Xcode 16.4 / CLT from media you already have"
    echo "   online : sudo xcode-select --install   (or install Xcode 16.4 from the App Store)"
    echo "   without it there is no clang, no python3, no git, no make -> no build."
  fi
  xcodebuild -version 2>/dev/null | head -2 || warn "xcodebuild missing"
  printf 'SDK: %s\n' "$(xcrun --show-sdk-version 2>/dev/null || echo missing)"
  command -v python3 >/dev/null && printf 'python3: %s\n' "$(python3 -V 2>&1)" || warn "python3 missing"
  command -v gmake   >/dev/null && printf 'gmake:   %s\n' "$(gmake --version | head -1)"     || warn "gmake missing (brew install make)"
  ensure_repo
}

# Fast preflight: every precondition the 20-40 minute build depends on, checked in seconds.
self_check() {
  say "preflight (no build, no changes)"
  local fails=0
  ok()   { printf '  OK   %s\n' "$*"; }
  bad()  { printf '  FAIL %s\n' "$*"; fails=$((fails+1)); }
  note() { printf '  ..   %s\n' "$*"; }

  [ "$(uname -s)" = "Darwin" ] && ok "macOS" || bad "not macOS"
  [ "$(uname -m)" = "x86_64" ] && ok "x86_64" || bad "architecture is $(uname -m), the build expects x86_64"

  if xcode-select -p >/dev/null 2>&1; then ok "developer tools at $(xcode-select -p)"; else bad "no developer tools (xcode-select --install)"; fi
  local sdk; sdk="$(xcrun --show-sdk-version 2>/dev/null || echo missing)"
  case "$sdk" in 15.[5-9]*|1[6-9].*|2[0-9].*) ok "SDK $sdk";; *) bad "SDK $sdk (need >= 15.5)";; esac
  command -v clang   >/dev/null && ok "clang $(clang --version 2>/dev/null | head -1)" || bad "clang missing"
  command -v python3 >/dev/null && ok "python3 $(python3 -V 2>&1)" || bad "python3 missing"
  command -v git     >/dev/null && ok "git $(git --version 2>/dev/null | awk '{print $3}')" || bad "git missing"
  command -v tar     >/dev/null && ok "tar" || bad "tar missing"
  if command -v gmake >/dev/null && gmake --version 2>/dev/null | head -1 | grep -q 'GNU Make 4'; then
    ok "gmake 4 present: $(gmake --version | head -1)"
  else
    note "no gmake 4; the build will compile GNU make 4.4.1 from the bundled tarball"
  fi

  local here; here="$(cd "$(dirname "$0")" && pwd)"
  local tools=""
  for t in "${here}/g1-tools" "${here}/../g1-tools" /Volumes/*/g1-tools /Volumes/*/HONOR-G1-FIRST-TOUCH/g1-tools; do
    [ -z "$tools" ] && [ -f "${t}/make-4.4.1.tar.gz" ] && tools="$t"
  done
  [ -n "$tools" ] && ok "make tarball: ${tools}/make-4.4.1.tar.gz" || bad "make-4.4.1.tar.gz not found (gmake 4 is then required)"

  if ensure_repo >/dev/null 2>&1 && [ -d "${REPO}/.git" ]; then
    ok "repo ${REPO} at $(git -C "${REPO}" rev-parse --short HEAD 2>/dev/null)"
    [ -f "${REPO}/research/stock-v243-offscreen-20261021/device-kextutil.sh" ] \
      && ok "build script present" || bad "device-kextutil.sh missing in the repo"
    [ -f "${REPO}/research/stock-v243-once-20261021/stock-v243-converged.patch" ] \
      && ok "patch assets present" || bad "patch assets missing in the repo copy"
  else
    bad "repository not found (expected g1-repo beside this script)"
  fi

  local nm="" nv=""
  for base in "${here}/g1-src" "${here}/../g1-src" /Volumes/*/g1-src /Volumes/*/HONOR-G1-FIRST-TOUCH/g1-src; do
    [ -z "$nm" ] && [ -d "${base}/nm/.git" ] && nm="${base}/nm"
    [ -z "$nv" ] && [ -d "${base}/nv/.git" ] && nv="${base}/nv"
  done
  if [ -n "$nm" ]; then
    local h; h="$(git -C "${nm}" rev-parse HEAD 2>/dev/null)"
    [ "$h" = "272ccd9da04ff5de95c2791b902fe17a3fa77ce7" ] && ok "NullMoth at pin" || bad "NullMoth at ${h:-unknown}, expected 272ccd9"
    local dirty; dirty="$(git -C "${nm}" status --porcelain --untracked-files=all 2>/dev/null | head -5)"
    [ -z "$dirty" ] && ok "NullMoth tree clean" || bad "NullMoth tree has untracked/modified files: $(echo "$dirty" | head -2 | tr '\n' ' ')"
  else
    bad "NullMoth source tree not found"
  fi
  if [ -n "$nv" ]; then
    local h2; h2="$(git -C "${nv}" rev-parse HEAD 2>/dev/null)"
    [ "$h2" = "e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb" ] && ok "OGKM at pin" || bad "OGKM at ${h2:-unknown}, expected e4a5faa"
    local dirty2; dirty2="$(git -C "${nv}" status --porcelain --untracked-files=all 2>/dev/null | head -5)"
    [ -z "$dirty2" ] && ok "OGKM tree clean" || bad "OGKM tree has untracked/modified files: $(echo "$dirty2" | head -2 | tr '\n' ' ')"
  else
    bad "OGKM source tree not found"
  fi

  local free_gb
  free_gb=$(df -g "${HOME}/Desktop" 2>/dev/null | awk 'NR==2 {print $4}')
  if [ -n "${free_gb:-}" ]; then
    [ "$free_gb" -ge 8 ] && ok "free space ${free_gb} GB" || bad "free space ${free_gb} GB (build needs ~8 GB)"
  fi

  printf '\n'
  if [ "$fails" -eq 0 ]; then
    say "preflight PASS - option 2 can run"
  else
    say "preflight FAIL - $fails problem(s) above; fix them before option 2"
  fi
  return 0
}

build_candidate() {
  say "build candidate (20-40 min)"
  ensure_repo
  # Tell the build exactly where the carried assets are, instead of relying on its own guessing: the
  # launcher is the only piece that knows where this folder currently lives.
  local here; here="$(cd "$(dirname "$0")" && pwd)"
  [ -d "${here}/g1-src/nm/.git" ] && export NM_SRC="${here}/g1-src/nm"
  [ -d "${here}/g1-src/nv/.git" ] && export NV_SRC="${here}/g1-src/nv"
  [ -d "${here}/g1-tools" ] && export G1_TOOLS="${here}/g1-tools"
  local script="${REPO}/research/stock-v243-offscreen-20261021/device-kextutil.sh"
  [ -f "${script}" ] || die "missing ${script}; run: git -C ${REPO} fetch origin && git -C ${REPO} checkout main"
  # A repository cloned on Windows can carry CRLF, which makes bash read "pipefail\r" as an option.
  if LC_ALL=C grep -q $'\r' "${script}" 2>/dev/null; then
    warn "${script} has CRLF line endings; converting the copy in place"
    LC_ALL=C sed -i '' $'s/\r$//' "${script}"
  fi
  local sdk
  sdk="$(xcrun --show-sdk-version 2>/dev/null || echo missing)"
  printf 'SDK: %s\n' "${sdk}"
  if [ "${sdk}" != "15.5" ] && [ "${ALLOW_OTHER_SDK:-0}" != "1" ]; then
    warn "the build expects SDK 15.5; select Xcode 16.4 first, or re-run with ALLOW_OTHER_SDK=1"
    printf 'continue anyway? [y/N] '
    [ "$(ask '')" = "y" ] || return 1
  fi
  bash "${script}" "${REPO}" "${WORK}" || die "build failed; see the log above"
  [ -d "${CAND}/NVRM.kext" ] || die "build finished but ${CAND}/NVRM.kext is missing"
  printf 'candidate ready: %s\n' "${CAND}/NVRM.kext"
}

do_backup() {
  say "backup (read only)"
  mkdir -p "${BACKUP}/Extensions" "${BACKUP}/KernelCollections"
  sudo cp -a /Library/Extensions/. "${BACKUP}/Extensions"/
  sudo cp -a /System/Library/KernelCollections/. "${BACKUP}/KernelCollections"/
  kextstat > "${BACKUP}/kextstat-before.txt"
  shasum -a 256 /System/Library/KernelCollections/*.kc > "${BACKUP}/kc-before.txt"
  local d
  for d in /System/Library/KernelCollections /Library/KernelCollections; do
    [ -d "${d}" ] && shasum -a 256 "${d}"/*.kc* >> "${BACKUP}/kc-before-all.txt" 2>/dev/null
  done
  ls -la /System/Library/KernelCollections /Library/KernelCollections > "${BACKUP}/kc-dirs.txt" 2>&1
  if [ -d /Library/Extensions/NVRM.kext ]; then echo present > "${BACKUP}/nvrm-was-installed.txt"
  else echo absent > "${BACKUP}/nvrm-was-installed.txt"; fi
  nvram boot-args > "${BACKUP}/boot-args-before.txt" 2>&1 || true
  csrutil status > "${BACKUP}/csrutil.txt" 2>&1 || true
  printf 'backup: %s\n' "${BACKUP}"
  printf 'send back: kextstat-before.txt kc-before-all.txt nvrm-was-installed.txt boot-args-before.txt\n'
}

do_install() {
  say "install (replace NVRM only, add -nvrmnogo)"
  [ -d "${CAND}/NVRM.kext" ] || die "no candidate at ${CAND}/NVRM.kext; run 2 first"
  [ -f "${BACKUP}/kextstat-before.txt" ] || die "no backup yet; run 3 first"
  printf 'will run:\n  rm -rf /Library/Extensions/NVRM.kext\n  cp -R %s/NVRM.kext /Library/Extensions/\n  nvram boot-args="<current> -nvrmnogo"\n  kmutil install --update-all\n' "${CAND}"
  printf 'no nvrmctl go, no Metal.\n'
  [ "$(ask 'type YES to continue:')" = "YES" ] || { warn "cancelled"; return 1; }

  sudo rm -rf /Library/Extensions/NVRM.kext
  sudo cp -R "${CAND}/NVRM.kext" /Library/Extensions/NVRM.kext
  sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  local current
  current="$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p' || true)"
  case "${current}" in
    *-nvrmnogo*) echo "boot-args already contain -nvrmnogo" ;;
    *) sudo nvram boot-args="${current} -nvrmnogo" ;;
  esac
  nvram boot-args > "${BACKUP}/boot-args-after.txt" 2>&1 || true
  sudo kmutil install --update-all
  say "installed. reboot now, then run this script and choose 5."
}

do_verify() {
  say "verify (after reboot)"
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' || warn "none of NVRM/NVAccel/NVRMFB is loaded"
  printf '\n-- NVRM properties\n'
  ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation)' || echo "(not readable)"
  printf '\n-- kernel log, last 5 min\n'
  log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"' 2>/dev/null | tail -40 || true
  printf '\n-- panic reports\n'
  ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 || echo "(none)"
  say "pass criteria: NVRM in kextstat; nvrm-autogo = off (-nvrmnogo); no panic."
}

do_rollback() {
  say "rollback"
  if [ -d "${BACKUP}/Extensions/NVRM.kext" ]; then
    echo "will restore the backed-up NVRM.kext"
  else
    echo "no previous NVRM in the backup; will remove the candidate"
  fi
  [ "$(ask 'type YES to continue:')" = "YES" ] || { warn "cancelled"; return 1; }
  if [ -d "${BACKUP}/Extensions/NVRM.kext" ]; then
    sudo rm -rf /Library/Extensions/NVRM.kext
    sudo cp -R "${BACKUP}/Extensions/NVRM.kext" /Library/Extensions/NVRM.kext
    sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  else
    sudo rm -rf /Library/Extensions/NVRM.kext
  fi
  if [ -f "${BACKUP}/boot-args-before.txt" ]; then
    sudo nvram boot-args="$(sed -n 's/.*boot-args[[:space:]]*//p' "${BACKUP}/boot-args-before.txt")"
  else
    sudo nvram -d boot-args
  fi
  sudo kmutil install --update-all
  say "rolled back. reboot and compare kextstat with ${BACKUP}/kextstat-before.txt"
}

menu() {
  while true; do
    say "menu"
    cat <<'EOF'
  0) preflight self-check (seconds, no build)
  1) check environment (read only)
  2) build the candidate (20-40 min)
  3) back up the current system (read only)
  4) install + -nvrmnogo (sudo, asks YES)
  5) verify after reboot
  6) roll back (sudo, asks YES)
  q) quit
EOF
    case "$(ask 'choice:')" in
      0) self_check ;;
      1) check_env ;;
      2) build_candidate ;;
      3) do_backup ;;
      4) do_install ;;
      5) do_verify ;;
      6) do_rollback ;;
      q|Q) break ;;
      *) warn "invalid choice" ;;
    esac
    printf '\n'
    ask 'press Enter to return to the menu...' >/dev/null
  done
}

menu
say "done. report: ${REPORT}"
printf 'recovery steps: RECOVERY-FROM-INSTALLER.md (boot the E: installer, open Terminal)\n'
