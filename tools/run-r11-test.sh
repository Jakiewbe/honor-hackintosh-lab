#!/bin/bash
# Host lifetime test. A compile failure is fatal: running a stale binary would report a false PASS.
set -uo pipefail
w=/mnt/d/Hactk/gpu-r5-20261017
o=$w/evidence/r11
b=$w/work
mkdir -p "$o"
{ uname -a; g++ --version | head -2; } > "$o/toolchain.txt" 2>&1
rm -f "$b/r11-lifetime"
if ! g++ -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter -O1 -g \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$o/device-lifetime-actual.cpp" -o "$b/r11-lifetime" > "$o/compile.txt" 2>&1; then
    echo "COMPILE=1 (see evidence/r11/compile.txt)"
    head -20 "$o/compile.txt"
    exit 2
fi
if ! head -2 "$o/device-lifetime-actual.cpp" | grep -q "^// source_sha256: "; then
    echo "PROVENANCE_MISSING: the generated test has no source fingerprint"; exit 2
fi
head -2 "$o/device-lifetime-actual.cpp" > "$o/provenance.txt"
echo "COMPILE=0"
"$b/r11-lifetime" > "$o/results.txt" 2>&1
rc=$?
echo "RUN=$rc" >> "$o/results.txt"
cat "$o/results.txt"
exit $rc
