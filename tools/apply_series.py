#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apply the approved NullMoth patch series to a clean candidate tree (no compiler needed).

The series is read from `scripts/gpu-safety-r5/native_compile.py` so this tool and the build gate can never
disagree about which patches make up the candidate. Every patch must apply and change the tree; a stale or
reordered series is an error, never a silent skip.

Usage:
    python3 tools/apply_series.py --candidate /path/to/clean/nullmoth --repo .
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERIES_SOURCE = ROOT / "scripts/gpu-safety-r5/native_compile.py"


def series():
    text = SERIES_SOURCE.read_text(encoding="utf-8")
    m = re.search(r"for number, name in enumerate\(\((.*?)\), 1\):", text, re.S)
    if not m:
        raise SystemExit("patch series tuple not found in native_compile.py")
    names = re.findall(r'"([^"]+\.patch)"', m.group(1))
    if not names:
        raise SystemExit("patch series tuple is empty")
    return names


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--candidate", type=Path, required=True)
    ap.add_argument("--repo", type=Path, default=ROOT)
    ap.add_argument("--tmp", type=Path, default=None)
    a = ap.parse_args()

    if a.tmp is None:
        import tempfile
        a.tmp = Path(tempfile.mkdtemp(prefix="series-"))
    a.tmp.mkdir(parents=True, exist_ok=True)
    patches = series()
    print(f"series: {len(patches)} patches")
    for index, name in enumerate(patches, 1):
        patch = a.repo / "patches" / name
        if not patch.is_file():
            patch = a.repo / "research/gpu-safety-r5" / name
        if not patch.is_file():
            raise SystemExit(f"missing patch file: {name}")
        # Normalize to LF before applying: a CRLF working copy would inject CRLF into the patched lines and
        # make the next patch in the series fail with a misleading context error.
        lf = a.tmp / name
        lf.write_bytes(patch.read_bytes().replace(b"\r\n", b"\n"))
        check = subprocess.run(["git", "-c", "core.autocrlf=false", "apply", "--check", str(lf)],
                               cwd=a.candidate, capture_output=True, text=True)
        if check.returncode != 0:
            raise SystemExit(f"{index:02d} {name}: does not apply\n{check.stderr[-400:]}")
        subprocess.run(["git", "-c", "core.autocrlf=false", "apply", "--whitespace=nowarn", str(lf)],
                       cwd=a.candidate, check=True)
        print(f"{index:02d} {name}: applied")
    print("RESULT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
