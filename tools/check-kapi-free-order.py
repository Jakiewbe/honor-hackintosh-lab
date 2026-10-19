#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check the free-order contract in KmsFreeDevice: callbacks must be quiesced before destructive cleanup.

Why: nvKmsKapiFreeNisoSurface() unregisters/unmaps surfaces that in-flight callbacks may still reference.
R36 frees both NISO surfaces *before* FREE_DEVICE and before the callback quiescence in
nvkms_xnu_try_close_kapi(), so a callback that is still running can touch freed state. This tool makes that
ordering measurable: it reports the actual position of each step and fails when the order is unsafe.

It reads a C file (the patched candidate copy), not a patch, so the result describes the code that would be
compiled.

Usage:
    python tools/check-kapi-free-order.py <nvkms-kapi.c>
"""
import re
import sys
from pathlib import Path


def find(text, pattern, start=0):
    m = re.search(pattern, text[start:], re.S)
    return None if m else -1 if False else (start + m.start() if m else None)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = Path(sys.argv[1])
    text = path.read_text(encoding="utf-8", errors="replace")

    fn = text.find("static NvBool KmsFreeDevice")
    if fn < 0:
        fn = text.find("KmsFreeDevice(struct NvKmsKapiDevice")
    if fn < 0:
        print("RESULT: FAIL (KmsFreeDevice not found; has R36 been applied?)")
        return 1
    end = text.find("\n}", fn)
    body = text[fn:end]

    pos = {}
    for name, pattern in (
        ("niso_semaphore", r"nvKmsKapiFreeNisoSurface\s*\(\s*device\s*,\s*&device->semaphore"),
        ("niso_notifier", r"nvKmsKapiFreeNisoSurface\s*\(\s*device\s*,\s*&device->notifier"),
        ("free_device_ioctl", r"NVKMS_IOCTL_FREE_DEVICE"),
        ("quiesce", r"nvkms_xnu_try_quiesce_kapi|nvkms_xnu_try_close_kapi"),
    ):
        m = re.search(pattern, body, re.S)
        pos[name] = len(body) + m.start() if m else None
        if m:
            pos[name] = m.start()

    print(f"file: {path}")
    for k in ("quiesce", "free_device_ioctl", "niso_semaphore", "niso_notifier"):
        print(f"  {k:18} {'absent' if pos[k] is None else pos[k]}")

    problems = []
    if pos["quiesce"] is None:
        problems.append("no callback quiescence call in KmsFreeDevice")
    else:
        for step in ("niso_semaphore", "niso_notifier"):
            if pos[step] is not None and pos["quiesce"] > pos[step]:
                problems.append(f"callbacks are quiesced after {step} is freed")
        if pos["free_device_ioctl"] is not None and pos["quiesce"] > pos["free_device_ioctl"]:
            problems.append("callbacks are quiesced after FREE_DEVICE")
    if pos["free_device_ioctl"] is not None and pos["niso_semaphore"] is not None \
            and pos["niso_semaphore"] < pos["free_device_ioctl"]:
        problems.append("NISO surfaces are freed before FREE_DEVICE is known to have succeeded")

    if problems:
        print("RESULT: FAIL")
        for p in problems:
            print("  -", p)
        return 1
    print("RESULT: PASS (quiesce first, NISO only after a successful FREE_DEVICE)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
