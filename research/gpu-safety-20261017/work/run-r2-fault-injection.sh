#!/bin/bash
set -euo pipefail
r=/mnt/d/Hactk/gpu-mainline-20261017
python3 "$r/work/r2_fault_injection.py"
g++ --version > "$r/evidence/r2/host-toolchain.txt"
for label in r1 r2; do
  g++ -std=c++17 -Wall -Wextra -Wconversion -Werror -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$r/evidence/r2/$label-actual-functions.cpp" -o "$r/evidence/r2/$label-host" > "$r/evidence/r2/$label-compile.txt" 2>&1
  set +e
  "$r/evidence/r2/$label-host" > "$r/evidence/r2/$label-results.txt" 2>&1
  rc=$?
  set -e
  echo "$rc" > "$r/evidence/r2/$label-exit.txt"
  cat "$r/evidence/r2/$label-results.txt"
  if [[ "$label" == r1 ]]; then [[ "$rc" == 1 ]]; else [[ "$rc" == 0 ]]; fi
 done
