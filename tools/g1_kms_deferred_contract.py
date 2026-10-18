#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compile and run the deferred-close contract on the host.

The unit under test (`research/gpu-safety-r5/darwin/kms_deferred.cpp`) is free of IOKit, so this needs
nothing but a C++ compiler. A failure is fail-closed: a non-zero exit from the binary, or a compile
error, makes this script return non-zero.

Usage:
    python tools/g1_kms_deferred_contract.py [--out DIR] [--cxx clang++]
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UNIT = ROOT / "research/gpu-safety-r5/darwin/kms_deferred.cpp"
TEST = ROOT / "research/gpu-safety-r5/darwin/tests/kms_deferred_contract.cpp"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/kms-deferred")
    ap.add_argument("--cxx", default="clang++")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    exe = out / "kms_deferred_contract"

    compile_cmd = [a.cxx, "-std=c++17", "-Wall", "-Wextra", "-Werror",
                   "-I", str(UNIT.parent), str(UNIT), str(TEST), "-o", str(exe)]
    print("compile:", " ".join(compile_cmd))
    rc = subprocess.run(compile_cmd).returncode
    if rc != 0:
        print("COMPILE_FAILED", rc)
        return 2

    run = subprocess.run([str(exe)])
    if run.returncode != 0:
        print("TEST_FAILED", run.returncode)
        return 1
    print("TEST_PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
