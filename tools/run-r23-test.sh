#!/bin/bash
# R23 PM-exclusion test driver.
#   * a brand-new working directory every run, so a stale binary can never be executed
#   * a compile failure exits non-zero and runs nothing
#   * the R22 baseline must FAIL the pin scenarios, the candidate must pass
#   * a deliberately corrupted source must fail to compile and must not produce a pass
#
# The source under test is the *patched* tree: apply the series first (roundtrip_r5.py --keep-applied),
# or point GPU_R23_SRC at any file that contains the functions.
set -uo pipefail
w=${GPU_R23_WORK:-/mnt/d/Hactk/gpu-r5-20261017}
here=$(cd "$(dirname "$0")" && pwd)
src=${GPU_R23_SRC:-$w/src/kexts/NVRM/os-nvkms-xnu.cpp}
out=${GPU_R23_OUT:-$w/evidence/r23}
baseline_commit=${GPU_R23_BASELINE:-37a7628}
work=$(mktemp -d /tmp/r23-XXXXXX) || exit 2
mkdir -p "$out"

sha() { sha256sum "$1" | cut -d' ' -f1; }
gen() { python3 "$here/r23-pm-fixture.py" "$1" "$2" || exit 2; }
compile() {
    local s=$1 b=$2; shift 2
    rm -f "$b"
    if ! g++ -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter -O1 -g \
        -fsanitize=address,undefined -fno-omit-frame-pointer "$@" \
        "$s" -o "$b" > "$out/compile-$(basename "$b").txt" 2>&1; then
        echo "COMPILE_FAIL $(basename "$b")"
        head -15 "$out/compile-$(basename "$b").txt"
        return 1
    fi
}

{
    echo "workdir=$work"
    echo "source=$src"
    echo "source_sha256=$(sha "$src")"
} > "$out/run.txt"

echo "=== candidate (R23)"
gen "$src" "$work/cand.cpp"
echo "generated_sha256=$(sha "$work/cand.cpp")" >> "$out/run.txt"
if ! compile "$work/cand.cpp" "$work/cand.bin" -DR23_HAS_PENDING; then
    echo "RESULT: COMPILE_FAILED - nothing was run" | tee -a "$out/run.txt"; exit 2
fi
if ! "$work/cand.bin" > "$out/candidate.txt" 2>&1; then
    echo "CANDIDATE: FAIL"; tail -6 "$out/candidate.txt"
    echo "RESULT: CANDIDATE_FAIL" >> "$out/run.txt"; exit 1
fi
echo "CANDIDATE: PASS ($(grep -c '^ok ' "$out/candidate.txt") checks)"

echo "=== baseline (R22, expected to FAIL)"
if ! git -C "$w/src" show "$baseline_commit:kexts/NVRM/os-nvkms-xnu.cpp" > "$work/base-src.cpp" 2>/dev/null; then
    echo "BASELINE: cannot read $baseline_commit from the source repo"; echo "RESULT: BASELINE_UNAVAILABLE" >> "$out/run.txt"; exit 2
fi
gen "$work/base-src.cpp" "$work/base.cpp"
if ! compile "$work/base.cpp" "$work/base.bin"; then
    echo "RESULT: BASELINE_COMPILE_FAILED" >> "$out/run.txt"; exit 2
fi
if "$work/base.bin" > "$out/baseline.txt" 2>&1; then
    echo "BASELINE: unexpectedly passed - the harness does not detect the defect"
    echo "RESULT: BASELINE_DID_NOT_FAIL" >> "$out/run.txt"; exit 1
fi
grep -q '^FAIL held pin -> suspend refuses' "$out/baseline.txt" || {
    echo "BASELINE: failed for the wrong reason"; tail -5 "$out/baseline.txt"
    echo "RESULT: BASELINE_WRONG_REASON" >> "$out/run.txt"; exit 1; }
echo "BASELINE: FAIL as expected (held pin -> suspend refuses)"

echo "=== negative control (corrupted source must not compile, must not run)"
cp "$work/cand.cpp" "$work/neg.cpp"
printf '\nthis is not C++;\n' >> "$work/neg.cpp"
if compile "$work/neg.cpp" "$work/neg.bin"; then
    echo "NEGATIVE: corrupted source compiled - harness is not fail-closed"
    echo "RESULT: NEGATIVE_DID_NOT_FAIL" >> "$out/run.txt"; exit 1
fi
[ -x "$work/neg.bin" ] && { echo "NEGATIVE: a binary exists for a failed compile"; exit 1; }
echo "NEGATIVE: compile failed, no binary, nothing ran"

echo "RESULT: PASS (candidate passes, R22 baseline fails, negative control fails closed)" | tee -a "$out/run.txt"
