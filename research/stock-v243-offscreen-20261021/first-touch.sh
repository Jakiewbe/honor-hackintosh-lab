#!/bin/bash
# First-touch experiment for the v2.4.3 ONCE candidate. Run on the macOS machine, with bash.
#
#   bash first-touch.sh backup     # step 0: snapshot everything the experiment can change
#   bash first-touch.sh install    # step 1: replace NVRM only, keep the others, add -nvrmnogo
#   bash first-touch.sh verify     # step 2: after reboot, record what actually loaded
#   bash first-touch.sh rollback   # undo: restore the snapshot and rebuild
#
# It never runs nvrmctl go, never signs, never touches Windows/EFI/BIOS/SIP.
set -euo pipefail

CAND=${CAND:-$HOME/Desktop/g1-kextutil/internal-products/package-products}
BACKUP=${BACKUP:-$HOME/Desktop/g1-first-touch}
ACTION=${1:-help}

case "$ACTION" in
  backup)
    mkdir -p "$BACKUP/Extensions" "$BACKUP/KernelCollections"
    sudo cp -a /Library/Extensions/. "$BACKUP/Extensions"/
    sudo cp -a /System/Library/KernelCollections/. "$BACKUP/KernelCollections"/
    kextstat > "$BACKUP/kextstat-before.txt"
    # Record whether a NullMoth NVRM was installed at all: this machine may have none, in which case
    # rollback means removing the candidate rather than restoring a release bundle.
    if [[ -d /Library/Extensions/NVRM.kext ]]; then
      echo present > "$BACKUP/nvrm-was-installed.txt"
    else
      echo absent > "$BACKUP/nvrm-was-installed.txt"
    fi
    shasum -a 256 /System/Library/KernelCollections/*.kc > "$BACKUP/kc-before.txt"
    # The experiment writes into the auxiliary collection, not only System/Boot: record every collection
    # the rebuild can touch, so a comparison after the fact is possible.
    for d in /System/Library/KernelCollections /Library/KernelCollections; do
      [[ -d "$d" ]] && shasum -a 256 "$d"/*.kc* >> "$BACKUP/kc-before-all.txt" 2>/dev/null || true
    done
    ls -la /System/Library/KernelCollections /Library/KernelCollections > "$BACKUP/kc-dirs.txt" 2>&1 || true
    csrutil status > "$BACKUP/csrutil.txt" 2>&1 || true
    nvram boot-args > "$BACKUP/boot-args-before.txt" 2>&1 || true
    echo "snapshot in $BACKUP; send kextstat-before.txt, kc-before.txt, boot-args-before.txt back"
    ;;

  install)
    [[ -d "$CAND/NVRM.kext" ]] || { echo "STOP: no NVRM.kext under $CAND"; exit 2; }
    [[ -f "$BACKUP/kextstat-before.txt" ]] || { echo "STOP: run 'backup' first"; exit 2; }
    # Only NVRM is replaced: NVRMFB/NVAccel stay as installed, so one variable changes at a time.
    sudo rm -rf /Library/Extensions/NVRM.kext
    sudo cp -R "$CAND/NVRM.kext" /Library/Extensions/NVRM.kext
    sudo chown -R root:wheel /Library/Extensions/NVRM.kext
    # -nvrmnogo: the kext loads but never starts the GPU; no firmware, no channels.
    current=$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p' || true)
    case "$current" in
      *-nvrmnogo*) echo "boot-args already contain -nvrmnogo" ;;
      *) sudo nvram boot-args="${current} -nvrmnogo" ;;
    esac
    nvram boot-args > "$BACKUP/boot-args-after.txt" 2>&1 || true
    sudo kmutil install --update-all 2>&1 | tee "$BACKUP/kmutil-install.txt"
    echo "reboot now; then run: bash first-touch.sh verify"
    ;;

  verify)
    kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' | tee "$BACKUP/kextstat-after.txt" || true
    ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation)' \
      | tee "$BACKUP/nvrm-properties.txt" || true
    log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"' 2>/dev/null \
      | tee "$BACKUP/nvrm-log.txt" || true
    echo "criteria: NVRM in kextstat; nvrm-autogo off; no panic/trap in the log"
    ;;

  rollback)
    if [[ -d "$BACKUP/Extensions/NVRM.kext" ]]; then
      sudo rm -rf /Library/Extensions/NVRM.kext
      sudo cp -R "$BACKUP/Extensions/NVRM.kext" /Library/Extensions/NVRM.kext
      sudo chown -R root:wheel /Library/Extensions/NVRM.kext
      echo "restored the bundle that was installed before the experiment"
    else
      # No release NVRM existed before: removing the candidate is the correct rollback.
      sudo rm -rf /Library/Extensions/NVRM.kext
      echo "no prior NVRM existed; removed the candidate instead"
    fi
    sudo nvram -d boot-args || true
    [[ -f "$BACKUP/boot-args-before.txt" ]] && sudo nvram boot-args="$(cat "$BACKUP/boot-args-before.txt" | sed -n 's/.*boot-args[[:space:]]*//p')" || true
    sudo kmutil install --update-all 2>&1 | tee "$BACKUP/kmutil-rollback.txt"
    echo "reboot, then compare kextstat with $BACKUP/kextstat-before.txt"
    ;;

  *)
    sed -n '2,10p' "$0"
    ;;
esac
