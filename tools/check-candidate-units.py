#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Keep the candidate translation-unit list and the candidate tree in sync.

`tools/g1_full_build.py` and `scripts/gpu-safety-r5/native_compile.py` both enumerate the NVRM units by
hard-coded name. A new file under `kexts/NVRM/` is therefore **not** compiled, and the merged code fails
later as an undefined symbol instead of here. This check makes that failure immediate:

  * every top-level `kexts/NVRM/*.c` / `*.cpp` must appear in the list parsed from g1_full_build.py;
  * every listed unit must exist in the candidate tree;
  * the two lists (g1_full_build vs native_compile) must agree.

Exit code is non-zero on any mismatch, so it can gate a merge.

Usage:
    python tools/check-candidate-units.py --candidate <nullmoth tree> [--json out.json]
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FULL_BUILD = ROOT / "tools/g1_full_build.py"
NATIVE = ROOT / "scripts/gpu-safety-r5/native_compile.py"


def parse_full_build():
    text = FULL_BUILD.read_text(encoding="utf-8")
    cpp = re.search(r"BASELINE_CPP = \{.*?for name in \((.*?)\)\}", text, re.S)
    c = re.search(r"BASELINE_C = \{(.*?)\}", text, re.S)
    if not cpp or not c:
        raise SystemExit("cannot parse the baseline unit lists from g1_full_build.py")
    names = {f"kexts/NVRM/{m}" for m in re.findall(r"'([A-Za-z0-9_.-]+\.cpp)'", cpp.group(1))}
    names |= {m.strip().strip("'") for m in c.group(1).split(",") if m.strip()}
    return names


def parse_native():
    text = NATIVE.read_text(encoding="utf-8")
    names = set()
    m = re.search(r"nvrm_units = \[(.*?)\]", text, re.S)
    if not m:
        raise SystemExit("cannot parse nvrm_units from native_compile.py")
    names |= {f"kexts/NVRM/{n}" for n in re.findall(r'"([A-Za-z0-9_.-]+\.(?:cpp|c))"', m.group(1))}
    # native_compile keeps the candidate C files in a separate list
    m = re.search(r"cand_files = \[(.*?)\]", text, re.S)
    if m:
        names |= set(re.findall(r'"(kexts/NVRM/[A-Za-z0-9_.-]+\.c)"', m.group(1)))
    return names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidate", required=True)
    ap.add_argument("--json")
    a = ap.parse_args()
    cand = Path(a.candidate).resolve()
    nvrm = cand / "kexts/NVRM"
    if not nvrm.is_dir():
        print(f"candidate tree has no kexts/NVRM: {cand}")
        return 2

    on_disk = {f"kexts/NVRM/{p.name}" for p in nvrm.iterdir()
               if p.is_file() and p.suffix in (".c", ".cpp")}
    full, native = parse_full_build(), parse_native()

    problems = []
    unlisted = sorted(on_disk - full)
    if unlisted:
        problems.append(f"present but not in the baseline list: {unlisted}")
    missing = sorted(full - on_disk)
    if missing:
        problems.append(f"listed but missing on disk: {missing}")
    if full != native:
        problems.append(f"g1_full_build and native_compile disagree: "
                        f"only-full={sorted(full - native)} only-native={sorted(native - full)}")

    print(f"on disk: {len(on_disk)}; g1_full_build: {len(full)}; native_compile: {len(native)}")
    for p in problems:
        print("PROBLEM:", p)
    print("RESULT:", "PASS" if not problems else "FAIL")
    if a.json:
        Path(a.json).write_text(json.dumps({"on_disk": sorted(on_disk), "full_build": sorted(full),
                                            "native": sorted(native), "problems": problems}, indent=1),
                                encoding="utf-8")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
