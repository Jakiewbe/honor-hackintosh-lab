#!/bin/bash
# R27 VBL reference test: deterministic interleavings, from the real functions.
#   * fresh temporary directory each run; compile failure exits non-zero and runs nothing
#   * the R22 baseline (unconditional release) must FAIL
#   * a corrupted source must fail to compile and must not produce a pass
set -uo pipefail
w=${GPU_R27_WORK:-/mnt/d/Hactk/gpu-r5-20261017}
here=$(cd "$(dirname "$0")" && pwd)
src=${GPU_R27_SRC:-$w/src/kexts/NMIntelFB/intelfb.cpp}
out=${GPU_R27_OUT:-$w/evidence/r27}
baseline_commit=${GPU_R27_BASELINE:-37a7628}
work=$(mktemp -d /tmp/r27-XXXXXX) || exit 2
mkdir -p "$out"
sha() { sha256sum "$1" | cut -d' ' -f1; }
gen() { python3 "$here/r27-vbl-fixture.py" "$1" "$2" || exit 2; }
compile() {
    local s=$1 b=$2; shift 2
    rm -f "$b"
    if ! g++ -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter -O1 -g \
        -fsanitize=address,undefined -fno-omit-frame-pointer "$@" "$s" -o "$b" \
        > "$out/compile-$(basename "$b").txt" 2>&1; then
        echo "COMPILE_FAIL $(basename "$b")"; head -10 "$out/compile-$(basename "$b").txt"; return 1
    fi
}
{ echo "workdir=$work"; echo "source=$src"; echo "source_sha256=$(sha "$src")"; } > "$out/run.txt"

echo "=== candidate (R27)"
gen "$src" "$work/cand.cpp"
echo "generated_sha256=$(sha "$work/cand.cpp")" >> "$out/run.txt"
compile "$work/cand.cpp" "$work/cand.bin" || { echo "RESULT: COMPILE_FAILED - nothing was run" | tee -a "$out/run.txt"; exit 2; }
# The emulated thread_call is allocated by the harness, not by the driver, so leak checking would report
# the harness itself. ASan still checks every access inside the extracted functions.
if ! ASAN_OPTIONS=detect_leaks=0 "$work/cand.bin" > "$out/candidate.txt" 2>&1; then
    echo "CANDIDATE: FAIL"; tail -8 "$out/candidate.txt"; echo "RESULT: CANDIDATE_FAIL" >> "$out/run.txt"; exit 1
fi
echo "CANDIDATE: PASS ($(grep -c '^ok ' "$out/candidate.txt") checks)"

echo "=== baseline (R22, expected to FAIL)"
git -C "$w/src" show "$baseline_commit:kexts/NMIntelFB/intelfb.cpp" > "$work/base-src.cpp" || { echo "RESULT: BASELINE_UNAVAILABLE" >> "$out/run.txt"; exit 2; }
gen "$work/base-src.cpp" "$work/base.cpp"
compile "$work/base.cpp" "$work/base.bin" || { echo "RESULT: BASELINE_COMPILE_FAILED" >> "$out/run.txt"; exit 2; }
if ASAN_OPTIONS=detect_leaks=0 "$work/base.bin" > "$out/baseline.txt" 2>&1; then
    echo "BASELINE: unexpectedly passed"; echo "RESULT: BASELINE_DID_NOT_FAIL" >> "$out/run.txt"; exit 1
fi
grep -q '^FAIL' "$out/baseline.txt" || { echo "BASELINE: failed for the wrong reason"; tail -5 "$out/baseline.txt"; exit 1; }
echo "BASELINE: FAIL as expected ($(grep -c '^FAIL' "$out/baseline.txt") checks failed)"

echo "=== negative control"
cp "$work/cand.cpp" "$work/neg.cpp"; printf '\nthis is not C++;\n' >> "$work/neg.cpp"
compile "$work/neg.cpp" "$work/neg.bin" && { echo "NEGATIVE: compiled"; exit 1; }
[ -x "$work/neg.bin" ] && { echo "NEGATIVE: binary exists after a failed compile"; exit 1; }
echo "NEGATIVE: compile failed, no binary, nothing ran"

echo "RESULT: PASS (candidate passes, R22 baseline fails, negative control fails closed)" | tee -a "$out/run.txt"
