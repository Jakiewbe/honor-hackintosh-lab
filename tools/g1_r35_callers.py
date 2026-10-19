#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Run the R35 caller contract: the two refused-close paths must now pass.

The fixture embeds the real bodies of `KmsFreeDevice`, `FreeDevice`, `dropKapiDevice()` and
`finishOrphanedDevice()` (R35 versions) and drives them through seven scenarios. Expectations:

  * every scenario exits 0, including `drop-backend-refused` and `orphan-backend-refused`;
  * compiling with `-DCOMPILE_NEGATIVE_CONTROL` must fail, so a stale binary cannot be reused.

Any mismatch makes this script exit non-zero (fail-closed).

Usage:
    python tools/g1_r35_callers.py [--cxx g++] [--out DIR]
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIR = ROOT / "research/gpu-safety-r5/r35-caller-evidence"
FIXTURE = DIR / "fixture.cpp"
UNIT = DIR / "kms_deferred.cpp"   # R30 deferral unit, embedded by the fixture's os-nvkms-xnu bodies
SCENARIOS = ["drop-success", "drop-other-user", "drop-backend-refused",
             "orphan-success", "orphan-other-users", "orphan-backend-refused",
             "pin-refused"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cxx", default="g++")
    ap.add_argument("--out", default="build/r35-callers")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    exe = out / "r35_callers"
    log = out / "compile.txt"

    cmd = [a.cxx, "-std=c++17", "-O1", "-Wall", "-I", str(DIR), str(FIXTURE), str(UNIT),
           "-o", str(exe)]
    print("compile:", " ".join(cmd))
    cp = subprocess.run(cmd, capture_output=True, text=True)
    log.write_text("ARGV=" + repr(cmd) + "\n" + cp.stdout + cp.stderr, encoding="utf-8")
    if cp.returncode != 0:
        print("COMPILE_FAILED", cp.returncode)
        print(cp.stderr[-2000:])
        # Workflow commands are parsed from stdout, so a compile failure becomes an annotation that can
        # be read back through the checks API when artifact download is unavailable.
        first = [l for l in cp.stderr.splitlines() if "error:" in l][:3] or cp.stderr.splitlines()[:3]
        for line in first:
            print("::error::" + line[:300])
        return 2

    failures = []
    for scenario in SCENARIOS:
        run = subprocess.run([str(exe), scenario], capture_output=True, text=True)
        (out / (scenario + ".txt")).write_text(run.stdout + run.stderr, encoding="utf-8")
        status = "PASS" if run.returncode == 0 else "FAIL"
        print(f"{status:4} {scenario}")
        if run.returncode != 0:
            failures.append(scenario)
            print((run.stdout + run.stderr).strip()[-400:])

    neg = subprocess.run([a.cxx, "-std=c++17", "-DCOMPILE_NEGATIVE_CONTROL", "-I", str(DIR), str(FIXTURE),
                          str(UNIT), "-o", str(out / "negative")], capture_output=True, text=True)
    (out / "compile-negative.txt").write_text(neg.stdout + neg.stderr, encoding="utf-8")
    if neg.returncode == 0:
        print("NEGATIVE_CONTROL_UNEXPECTEDLY_COMPILED")
        failures.append("compile-negative-control")
    else:
        print("PASS compile-negative-control (nonzero as expected)")

    print(f"RESULT: {len(SCENARIOS) - len([f for f in failures if f != 'compile-negative-control'])}"
          f"/{len(SCENARIOS)} scenarios; failures={failures}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
