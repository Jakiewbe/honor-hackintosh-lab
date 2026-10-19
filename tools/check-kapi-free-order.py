#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check the free-order contract in KmsFreeDevice: quiesce first, NISO only after a successful free.

Why: nvKmsKapiFreeNisoSurface() unregisters/unmaps surfaces that in-flight callbacks may still reference.
R36 frees both NISO surfaces before FREE_DEVICE and before the callback quiescence, so a callback that is
still running can touch freed state, and a failed FREE_DEVICE leaves NVKMS holding handles whose surfaces
are already gone.

What this version requires (it used to accept a function containing only a quiesce call):
  * comments are stripped first, so a comment cannot satisfy a step;
  * every step must appear exactly once - a missing or duplicated step is a failure, not a skip;
  * order: quiesce < FREE_DEVICE < NISO semaphore < NISO notifier;
  * FREE_DEVICE must be guarded by a failing check (`if (!nvkms_ioctl_from_kapi`).

Usage:
    python tools/check-kapi-free-order.py <nvkms-kapi.c>
    python tools/check-kapi-free-order.py --self-test
"""
import re
import sys
import tempfile
from pathlib import Path

STEPS = (
    ("quiesce", r"nvkms_xnu_try_quiesce_kapi\s*\("),
    ("free_device_ioctl", r"NVKMS_IOCTL_FREE_DEVICE"),
    ("niso_semaphore", r"nvKmsKapiFreeNisoSurface\s*\(\s*device\s*,\s*&device->semaphore"),
    ("niso_notifier", r"nvKmsKapiFreeNisoSurface\s*\(\s*device\s*,\s*&device->notifier"),
)


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", " ", text)


def function_body(text, name="KmsFreeDevice"):
    m = re.search(r"(?:static\s+NvBool\s+|NvBool\s+)?%s\s*\(struct NvKmsKapiDevice[^)]*\)\s*\{" % name, text)
    if not m:
        return None
    start = m.end() - 1
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return None


def analyse(text):
    text = strip_comments(text)
    body = function_body(text)
    if body is None:
        return False, ["KmsFreeDevice not found"], {}
    positions, problems = {}, []
    for name, pattern in STEPS:
        hits = [m.start() for m in re.finditer(pattern, body)]
        positions[name] = hits[0] if hits else None
        if not hits:
            problems.append(f"{name} is absent")
        elif len(hits) > 1:
            problems.append(f"{name} appears {len(hits)} times")
    if problems:
        return False, problems, positions

    q, f, s, n = (positions["quiesce"], positions["free_device_ioctl"],
                  positions["niso_semaphore"], positions["niso_notifier"])
    if not (q < f):
        problems.append("callbacks are quiesced after FREE_DEVICE")
    if not (f < s and f < n):
        problems.append("NISO surfaces are freed before FREE_DEVICE")
    if s < f or n < f:
        pass  # already reported above
    if not re.search(r"if\s*\(\s*!\s*nvkms_ioctl_from_kapi", body):
        problems.append("FREE_DEVICE is not guarded by a failing check")
    # F1: ordering alone is not enough - a NISO free inside the FREE_DEVICE failure branch would run on the
    # very path that must leave NVKMS resources untouched.
    guard = re.search(r"if\s*\(\s*!\s*nvkms_ioctl_from_kapi.*?\)\s*\{", body, re.S)
    if guard:
        start = guard.end() - 1
        depth = 0
        end = None
        for k in range(start, len(body)):
            if body[k] == "{":
                depth += 1
            elif body[k] == "}":
                depth -= 1
                if depth == 0:
                    end = k
                    break
        branch = body[start:end] if end else ""
        if "nvKmsKapiFreeNisoSurface" in branch:
            problems.append("a NISO surface is freed inside the FREE_DEVICE failure branch")
    return not problems, problems, positions


def self_test():
    cases = {
        "complete": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    if (!nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0)) return NV_FALSE;
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);
    return NV_TRUE; }""", True),
        "incomplete": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    nvkms_xnu_try_quiesce_kapi(device->pKmsOpen); }""", False),
        "comment_only": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    /* NVKMS_IOCTL_FREE_DEVICE nvKmsKapiFreeNisoSurface(&device->semaphore) */
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    return NV_TRUE; }""", False),
        "reversed": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);
    if (!nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0)) return NV_FALSE;
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    return NV_TRUE; }""", False),
        "duplicate": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    if (!nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0)) return NV_FALSE;
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);
    return NV_TRUE; }""", False),
        "niso_on_failure": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    if (!nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0)) {
        nvKmsKapiFreeNisoSurface(device, &device->semaphore);
        return NV_FALSE; }
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);
    return NV_TRUE; }""", False),
    "unguarded": ("""static NvBool KmsFreeDevice(struct NvKmsKapiDevice *device){
    if (!nvkms_xnu_try_quiesce_kapi(device->pKmsOpen)) return NV_FALSE;
    nvkms_ioctl_from_kapi(device->pKmsOpen, NVKMS_IOCTL_FREE_DEVICE, 0, 0);
    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);
    return NV_TRUE; }""", False),
    }
    failures = 0
    for name, (text, expected) in cases.items():
        ok, problems, _ = analyse(text)
        status = "PASS" if ok else "FAIL"
        good = ok == expected
        print(f"{'ok  ' if good else 'BAD '} {name:12} expected {'PASS' if expected else 'FAIL'} got {status}"
              + ("" if good else "  " + "; ".join(problems)))
        failures += 0 if good else 1
    print(f"self-test: {len(cases) - failures}/{len(cases)}")
    return 0 if failures == 0 else 1


def main():
    if "--self-test" in sys.argv:
        return self_test()
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = Path(sys.argv[1])
    text = path.read_text(encoding="utf-8", errors="replace")
    ok, problems, positions = analyse(text)
    print(f"file: {path}")
    for name, _ in STEPS:
        print(f"  {name:18} {'absent' if positions.get(name) is None else positions[name]}")
    if ok:
        print("RESULT: PASS (quiesce first, FREE_DEVICE guarded, NISO only afterwards)")
        return 0
    print("RESULT: FAIL")
    for p in problems:
        print("  -", p)
    return 1


if __name__ == "__main__":
    sys.exit(main())
