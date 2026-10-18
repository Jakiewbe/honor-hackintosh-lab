#!/bin/bash
# R24 PM-exclusion test driver (begin / commit / abort).
#   * a brand-new working directory every run: a stale binary can never be executed
#   * a compile failure exits non-zero and runs nothing
#   * the R22 baseline must FAIL the "a held pin blocks the suspend" checks
#   * a deliberately corrupted source must fail to compile and must not produce a pass
set -uo pipefail
w=${GPU_R24_WORK:-/mnt/d/Hactk/gpu-r5-20261017}
here=$(cd "$(dirname "$0")" && pwd)
src=${GPU_R24_SRC:-$w/src/kexts/NVRM/os-nvkms-xnu.cpp}
out=${GPU_R24_OUT:-$w/evidence/r24}
baseline_commit=${GPU_R24_BASELINE:-37a7628}
work=$(mktemp -d /tmp/r24-XXXXXX) || exit 2
mkdir -p "$out"

sha() { sha256sum "$1" | cut -d' ' -f1; }
gen() { python3 "$here/r24-pm-fixture.py" "$1" "$2" || exit 2; }
compile() {
    local s=$1 b=$2; shift 2
    rm -f "$b"
    if ! g++ -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter -O1 -g \
        -fsanitize=address,undefined -fno-omit-frame-pointer "$@" \
        "$s" -o "$b" > "$out/compile-$(basename "$b").txt" 2>&1; then
        echo "COMPILE_FAIL $(basename "$b")"; head -15 "$out/compile-$(basename "$b").txt"; return 1
    fi
}

{ echo "workdir=$work"; echo "source=$src"; echo "source_sha256=$(sha "$src")"; } > "$out/run.txt"

echo "=== candidate (R24)"
gen "$src" "$work/cand.cpp"
echo "generated_sha256=$(sha "$work/cand.cpp")" >> "$out/run.txt"
if ! compile "$work/cand.cpp" "$work/cand.bin" -DR24_HAS_PENDING; then
    echo "RESULT: COMPILE_FAILED - nothing was run" | tee -a "$out/run.txt"; exit 2
fi
if ! "$work/cand.bin" > "$out/candidate.txt" 2>&1; then
    echo "CANDIDATE: FAIL"; tail -8 "$out/candidate.txt"; echo "RESULT: CANDIDATE_FAIL" >> "$out/run.txt"; exit 1
fi
echo "CANDIDATE: PASS ($(grep -c '^ok ' "$out/candidate.txt") checks)"

echo "=== baseline (R22, expected to FAIL)"
if ! git -C "$w/src" show "$baseline_commit:kexts/NVRM/os-nvkms-xnu.cpp" > "$work/base-src.cpp" 2>/dev/null; then
    echo "RESULT: BASELINE_UNAVAILABLE" >> "$out/run.txt"; exit 2
fi
gen "$work/base-src.cpp" "$work/base.cpp"
compile "$work/base.cpp" "$work/base.bin" || { echo "RESULT: BASELINE_COMPILE_FAILED" >> "$out/run.txt"; exit 2; }
if "$work/base.bin" > "$out/baseline.txt" 2>&1; then
    echo "BASELINE: unexpectedly passed"; echo "RESULT: BASELINE_DID_NOT_FAIL" >> "$out/run.txt"; exit 1
fi
grep -q '^FAIL begin closes pin admission\|^FAIL commit refuses while the pin is held' "$out/baseline.txt" || {
    echo "BASELINE: failed for the wrong reason"; tail -6 "$out/baseline.txt"
    echo "RESULT: BASELINE_WRONG_REASON" >> "$out/run.txt"; exit 1; }
echo "BASELINE: FAIL as expected (a held pin does not block the suspend)"

echo "=== negative control"
cp "$work/cand.cpp" "$work/neg.cpp"; printf '\nthis is not C++;\n' >> "$work/neg.cpp"
compile "$work/neg.cpp" "$work/neg.bin" && { echo "NEGATIVE: compiled - not fail-closed"; exit 1; }
[ -x "$work/neg.bin" ] && { echo "NEGATIVE: binary exists after a failed compile"; exit 1; }
echo "NEGATIVE: compile failed, no binary, nothing ran"

echo "RESULT: PASS (candidate passes, R22 baseline fails, negative control fails closed)" | tee -a "$out/run.txt"
