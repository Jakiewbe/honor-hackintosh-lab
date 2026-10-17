#!/bin/bash
set -euo pipefail
r=/mnt/d/Hactk/gpu-mainline-20261017
logs="$r/evidence/host-copy"
mkdir -p "$logs"
g++ --version > "$logs/toolchain.txt"
g++ -std=c++17 -Wall -Wextra -Wconversion -Werror -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
  -I "$r/candidate/nullmoth-v2.3.3-gpu-safety-r1/kexts/NVRM/accel" \
  "$r/work/test_frame_copy_checked.cpp" -o "$logs/frame-copy-host" > "$logs/compile.txt" 2>&1
"$logs/frame-copy-host" | tee "$logs/results.txt"
echo 'HOST-TEST only: actual CPU copy helper; no driver, IOKit or GPU execution'
