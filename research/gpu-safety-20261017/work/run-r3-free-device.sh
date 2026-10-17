#!/bin/bash
set -euo pipefail
r=/mnt/d/Hactk/gpu-mainline-20261017
python3 "$r/work/r3_free_device_fixture.py"
for label in original candidate; do
  gcc -std=gnu11 -Wall -Wextra -Werror -Wno-misleading-indentation -g -O1 -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$r/evidence/r3/$label-free-device-fixture.c" -o "$r/evidence/r3/$label-free-device-host" > "$r/evidence/r3/$label-fixture-compile.txt" 2>&1
  for mode in null populated partial; do
    set +e
    UBSAN_OPTIONS=halt_on_error=1 "$r/evidence/r3/$label-free-device-host" "$mode" > "$r/evidence/r3/$label-$mode-results.txt" 2>&1
    rc=$?
    set -e
    echo "$rc" > "$r/evidence/r3/$label-$mode-exit.txt"
    echo "$label $mode exit $rc"
    if [[ "$label" == original && "$mode" == null ]]; then [[ "$rc" != 0 ]]; else [[ "$rc" == 0 ]]; fi
  done
 done
