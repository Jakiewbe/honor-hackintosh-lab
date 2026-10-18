#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Emit the `g_nvid_string.c` that the OGKM build generates with GENERATE_NVIDSTRING.

Why this exists: `pNV_KMS_ID` has no definition in the source tree. It is produced by `utils.mk:555`
(`GENERATE_NVIDSTRING`), which writes exactly two lines:

    const char <NAME>[] = "nvidia id: <description> for <arch>  <version>  <build type>  (<user>@<host>)  <date>";
    const char *const p<NAME> = <NAME> + 11;

The `+ 11` skips the literal prefix "nvidia id: ". A build that does not run that Makefile macro must
reproduce this file, otherwise `pNV_KMS_ID` stays undefined. This script does that deterministically,
so the generated object can be inspected and compared instead of guessed at.

The version string is an input, not a discovery: pass the value that the pinned tree carries.

Usage:
    python tools/gen-nvid-string.py --version 610.57.04 --out g_nvid_string.c
"""
import argparse
import datetime
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", default="NV_KMS_ID", help="macro argument $(1); the pointer gets a p prefix")
    ap.add_argument("--description", default="NVIDIA UNIX Open Kernel Mode Setting Driver")
    ap.add_argument("--arch", default="x86_64")
    ap.add_argument("--version", required=True, help="NVIDIA_NVID_VERSION, e.g. 610.57.04")
    ap.add_argument("--build-type", default="Release Build")
    ap.add_argument("--date", default=None, help="defaults to today; the real build uses `date` at build time")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    date = a.date or datetime.date.today().strftime("%a %b %d %H:%M:%S %Z %Y")
    text = f"nvidia id: {a.description} for {a.arch}  {a.version}  {a.build_type}  ({date})"
    body = (f'const char {a.name}[] = "{text}";\n'
            f'const char *const p{a.name} = {a.name} + 11;\n')
    Path(a.out).write_text(body, encoding="utf-8", newline="\n")
    print(f"wrote {a.out}:")
    print(body.rstrip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
