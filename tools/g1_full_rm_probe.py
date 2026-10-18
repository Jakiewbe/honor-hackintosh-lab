#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compile the whole OGKM RM layer under the Darwin toolchain and measure what stays undefined.

This is the decisive experiment for "can NVRM be rebuilt from public source": it does not sample and it
does not stop at the first failure. It compiles every `.c` under `src/nvidia/src` and
`src/nvidia/generated`, adds the one build-generated file (`g_nvid_string.c`, see
`tools/gen-nvid-string.py`), links whatever compiled, and reports the undefined symbols by provider class.

Scope and honesty notes
-----------------------
* Report-only. Nothing here produces a loadable kext: the link is `-nostdlib -kext` with unresolved
  imports allowed, which is exactly why the undefined list is the measurement, not the link exit code.
* `-DNVRM` is restored on purpose: `nv_state_t` lives inside `#ifdef NVRM` in the unix headers.
* The macro set is the fixed one this project has used since the probe rounds; it is *not* re-derived
  from the pinned Makefile here. A compile count from this tool says "the toolchain can parse it",
  nothing about semantic equivalence with the upstream build.

Usage:
    python tools/g1_full_rm_probe.py --nv /path/to/open-gpu-kernel-modules --out /path/to/out
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# Experiment 3: PORT_IS_KERNEL_BUILD=0 makes nvlog_defs.h define PORT_ATOMIC itself, which tells us
# whether the remaining failures are libc-shaped (usermode path) rather than port-layer-shaped.
# PORT_* are makefile switches, not source: nvport.h/nvassert.h refuse to compile without them and the
# tree never defines them. Release build == checked build off. Recorded here so the value is visible.
DEFINES = ["-DNV_UNIX", "-DNV_LINUX", "-DNVRM", "-D_LANGUAGE_C",
           "-DPORT_IS_CHECKED_BUILD=0", "-DPORT_IS_KERNEL_BUILD=0",
           "-DPORT_BREAKPOINT_CHECKED(x)=((void)0)", "-DPORT_COVERAGE_PUSH_OFF()", "-DPORT_COVERAGE_POP()"]
CFLAGS = ["-x", "c", "-std=gnu11", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
          "-mkernel", "-nostdinc", "-DKERNEL", "-DKERNEL_PRIVATE", "-DDRIVER_PRIVATE", "-DAPPLE",
          "-DNeXT", "-fno-builtin", "-fno-common", "-O1", "-w"]
INCLUDES = [
    "src/nvidia/arch/nvalloc/unix/include", "src/nvidia/arch/nvalloc/common/inc",
    "src/nvidia/arch/nvalloc/common/inc/gsp", "src/nvidia/inc", "src/nvidia/inc/os",
    "src/nvidia/inc/kernel", "src/nvidia/interface", "src/nvidia/inc/libraries",
    "src/nvidia/src/libraries", "src/nvidia/generated", "src/nvidia/src/mm/uvm/interface",
    "src/common/sdk/nvidia/inc", "src/common/sdk/nvidia/inc/hw", "src/common/inc",
    "src/common/shared/inc", "src/common/nvlink/interface", "src/common/inc/swref",
    "src/common/inc/swref/published", "src/common/uproc/os/libos-v2.0.0/include",
    "src/common/uproc/os/common/include", "src/common/inc/displayport",
    "src/common/nvlink/inband/interface", "src/common/unix/nvidia-push/interface",
    "src/common/unix/common/inc", "src/nvidia-modeset/include", "src/nvidia-modeset/kapi/include",
    "src/common/softfloat/nvidia", "src/common/softfloat/source/include",
    "src/common/softfloat/source/8086-SSE", "src/common/softfloat/source",
    "src/common/unix/nvidia-headsurface", "src/nvidia/src/libraries/libspdm/nvidia",
    "src/nvidia/src/libraries/libspdm/3.5.0/include",
]


def provider_class(sym):
    name = sym.lstrip("_")
    if name.startswith(("IO", "OS", "gIO")):
        return "iokit/libkern"
    if name.startswith(("nvKms",)):
        return "ogkm-nvkms"
    if name.startswith(("nvrm_",)):
        return "nullmoth"
    if (name.startswith(("rm_", "Rm", "Nv04", "Nv01", "nvoc_", "Cli", "gpumgr", "kbus", "kdisp", "os"))
            or re.match(r"^nv[A-Z]", name)):
        return "ogkm-rm"
    if name.startswith(("_Z", "__Z")):
        return "c++"
    if name.startswith(("mach_", "kern_", "thread_", "clock_", "absolutetime", "ml_")):
        return "mach/kern"
    return "unclassified"


def run(cmd, cwd, log):
    with open(log, "w", encoding="utf-8") as fh:
        proc = subprocess.run(cmd, cwd=str(cwd), stdout=fh, stderr=subprocess.STDOUT)
    return proc.returncode


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nv", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--sdk", default=None)
    a = ap.parse_args()
    nv = Path(a.nv).resolve()
    out = Path(a.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    sdk = a.sdk or subprocess.check_output(["xcrun", "--show-sdk-path"], text=True).strip()

    inc = ["-I" + sdk + "/System/Library/Frameworks/Kernel.framework/Headers",
           "-I" + sdk + "/System/Library/Frameworks/Kernel.framework/Headers/IOKit"]
    inc += ["-I" + str(nv / d) for d in INCLUDES if (nv / d).is_dir()]

    files = []
    for d in ("src/nvidia/src", "src/nvidia/generated"):
        files.extend(sorted((nv / d).rglob("*.c")))
    # user-space helpers (pthread) are not kext code
    files = [f for f in files if "src/common/src/" not in f.as_posix()]

    report = {"files": len(files), "compiled": 0, "failed": [], "skipped": 0}
    objs = []
    for i, src in enumerate(files):
        obj = out / ("o-" + src.stem + "-" + str(i) + ".o")
        log = out / ("c-" + src.stem + "-" + str(i) + ".txt")
        cmd = ["xcrun", "clang", *CFLAGS, *DEFINES, *inc, "-I" + str(src.parent),
               "-c", str(src), "-o", str(obj)]
        rc = run(cmd, nv, log)
        if rc == 0:
            report["compiled"] += 1
            objs.append(obj)
        else:
            errs = [l for l in log.read_text(encoding="utf-8", errors="replace").splitlines() if "error:" in l][:1]
            if len(report["failed"]) < 40:
                report["failed"].append({"file": src.relative_to(nv).as_posix(), "error": errs})
    report["objects"] = len(objs)

    # the one build-generated file
    gen = out / "g_nvid_string.c"
    gen.write_text('const char NV_KMS_ID[] = "nvidia id: NVIDIA UNIX Open Kernel Mode Setting Driver for x86_64  '
                   '610.57.04  Release Build  (g1 probe)";\n'
                   'const char *const pNV_KMS_ID = NV_KMS_ID + 11;\n', encoding="utf-8")
    genc = ["xcrun", "clang", *CFLAGS, *DEFINES, *inc, "-c", str(gen), "-o", str(out / "g_nvid_string.o")]
    if run(genc, nv, out / "c-g_nvid_string.txt") == 0:
        objs.append(out / "g_nvid_string.o")
        report["generated_object"] = True

    if objs:
        exe = out / "NVRM-fullrm.kext/Contents/MacOS/NVRM"
        exe.parent.mkdir(parents=True, exist_ok=True)
        link = ["xcrun", "clang++", "-arch", "x86_64", "-mmacosx-version-min=15.5", "-fapple-kext",
                "-isysroot", sdk, "-nostdlib", "-Xlinker", "-kext", "-lkmodc++", "-lkmod", "-lcc_kext",
                *[str(o) for o in objs], "-o", str(exe)]
        rc = run(link, nv, out / "link.txt")
        report["link_exit"] = rc
        if rc == 0:
            und = out / "undefined.txt"
            run(["xcrun", "nm", "-u", str(exe)], nv, und)
            syms = [l.strip() for l in und.read_text(encoding="utf-8", errors="replace").splitlines()
                    if l.strip().startswith("_")]
            classes = collections.Counter(provider_class(s) for s in syms)
            report.update({"size": exe.stat().st_size, "undefined": len(syms), "classes": dict(classes),
                           "ogkm_rm_sample": [s for s in syms if provider_class(s) == "ogkm-rm"][:20]})
        else:
            report["link_errors"] = [l for l in (out / "link.txt").read_text(encoding="utf-8", errors="replace")
                                     .splitlines() if "error" in l.lower()][:5]
    (out / "report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k not in ("failed", "ogkm_rm_sample")}, indent=1))
    print("failed sample:", [f["file"] for f in report["failed"]][:8])
    return 0


if __name__ == "__main__":
    sys.exit(main())
