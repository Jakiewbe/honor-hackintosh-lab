#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Classify the undefined (imported) symbols of a linked kext by who is expected to provide them.

Usage: python tools/classify-imports.py <nm -u text file> [--json out.json]

Categories are naming heuristics, not evidence of a kernel export or provider.

Categories:
  mach/kern      exported by kernel (com.apple.kpi.mach, kern.*)
  iokit/libkern  C functions and C++ methods of IOKit / libkern classes
  c++ runtime    __cxa_*, __gxx_*, operator new/delete, unwinding
  unclassified   anything the rules do not recognise - the list that needs a human
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path
from g1_symbol_identity import identity, parse_nm_undefined, source_spelling

KERNEL_PREFIXES = (
    "kern_", "mach_", "thread_", "clock_", "absolutetime", "nanoseconds", "vm_", "kmem_", "ml_",
    "lck_", "current_", "wait_", "kauth", "uio", "proc_", "bzero", "memcpy", "memset", "strlcpy",
    "kprintf", "panic", "PE_", "_ZN6kernel", "stack_chk", "assert_wait", "copyin", "copyout", "bzero", "get_task_pmap", "task_", "ipc_", "os_",
)
LIBKERN_CLASSES = {
    "OSObject", "OSMetaClass", "OSMetaClassBase", "OSDictionary", "OSSymbol", "OSArray", "OSData",
    "OSString", "OSNumber", "OSBoolean", "OSSet", "OSIterator", "OSCollection", "OSSerialize",
    "OSOrderedSet", "OSData", "IOLock", "IORecursiveLock", "IOSimpleLock",
}
CPP_RUNTIME = ("__cxa_", "__gxx_", "_Unwind", "_Znwm", "_ZdlPv", "_Znam", "_ZdaPv", "_ZSt")


GAPS = {"nvKms": "ogkm-nvkms", "nvKmsKapi": "ogkm-nvkms", "rm_": "ogkm-rm", "nvrm_": "nullmoth-internal",
        "Rm": "ogkm-rm-core", "Nv01": "ogkm-rm-core", "Nv04": "ogkm-rm-core", "os_": "ogkm-os"}
# Nv\d\d* are RM API entry points (Nv04AllocContextDmaKernel ...); they come from the RM core, not the Unix layer.


def classify(sym: str) -> str:
    s = source_spelling(sym)
    for prefix, gap in GAPS.items():
        if s.startswith(prefix):
            return gap
    if any(s.startswith(p) for p in KERNEL_PREFIXES) or s.startswith(("kOS", "kernel_", "semaphore_", "vfs_", "vnode_", "vn_", "sysctl", "snprintf", "vsnprintf", "strcmp", "strlen", "strncmp", "memcmp", "memmove", "read_random", "page_size")):
        return "mach/kern"
    if s.startswith(CPP_RUNTIME):
        return "c++ runtime"
    m = re.match(r"_ZN[KV]?(\d+)(\w+)", s)
    if m:
        n = int(m.group(1))
        cls = m.group(2)[:n]
        if cls.startswith("IO") or cls.startswith("Apple"):
            return "iokit/libkern"
        if cls in LIBKERN_CLASSES:
            return "iokit/libkern"
        if cls.startswith("std") or cls.startswith("__"):
            return "c++ runtime"
        return "unclassified"
    if s.startswith("IO") or s.startswith("OS") or s.startswith("gIO"):
        return "iokit/libkern"
    # RM / NVOC internals: nvEvo*, nvHs*, nvGe*, nvRm*, gpumgr*, rmap*, port*, memdesc*, serv*, intr*,
    # Cli*/PEX_*, __nvoc_*, *_IMPL helpers. The shipping NVRM contains all of these.
    RM_PREFIXES = ("nvEvo", "nvHs", "nvGe", "nvRm", "nvGp", "nv_", "gpumgr", "rmap", "port", "memdesc",
                   "serv", "intr", "Cli", "PEX_", "__nvoc_", "__rm", "_IMPL", "kai", "gpu", "_f16", "_f32")
    if s.startswith(RM_PREFIXES) or s.endswith("_IMPL"):
        return "ogkm-rm-core"
    if s.startswith(("bitV", "thre", "os_")):
        return "ogkm-rm-core"
    # Remaining RM/NVOC internals seen in the mixed link: __nvoc_*, _nv*, kbus*, kdisp*, _f16/_f32 softfloat,
    # global RM services (g_pSys, g_resServ), ACPI helpers, *_KERNEL entry points.
    # Preserve the C identifier's own underscores. These remain naming heuristics.
    if (s.startswith(("nvoc_", "kbus", "kdisp", "kfifo", "kgsp", "g_", "acpiDsm"))
            or s.endswith("_KERNEL")
            or (len(s) > 2 and s.startswith("nv") and s[2].isupper())
            or (len(s) > 3 and s.startswith("f32") or s.startswith("f16"))
            or s.startswith(("osC", "osG", "osHandle", "osIs", "osMap", "osModify", "osQueue", "osRead",
                              "osRun", "osSanity", "osUnmap", "osWrite", "rmDevice", "rmGpu", "pNV", "pciPbi",
                              "rcdb", "refFind", "nvlog", "rmIntr", "tls", "tmrCtrl", "transformGid",
                              "workItem", "ui32_"))):
        return "ogkm-rm-core"
    if s.startswith("_Z") or s.startswith("std"):
        return "c++ runtime"
    return "unclassified"


def main():
    path = Path(sys.argv[1])
    out = None
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
    syms = parse_nm_undefined(path.read_text(encoding="utf-8"))
    cats = Counter(classify(s) for s in syms)
    unknown = [s for s in syms if classify(s) == "unclassified"]
    rec = {"schema": "honor.g1.import-classification.v2", "file": str(path),
           "level": "NAME_HEURISTICS_NOT_PROVIDER_OR_EXPORT_PROOF",
           "symbols": len(syms), "categories": dict(cats),
           "records": [dict(identity(s), category=classify(s)) for s in syms],
           "unclassified": unknown, "unclassified_count": len(unknown)}
    for k, v in cats.most_common():
        print(f"{v:6}  {k}")
    print(f"{len(syms):6}  TOTAL")
    if unknown:
        print("\nunclassified (first 20):")
        for s in unknown[:20]:
            print("   ", s)
    if out:
        out.write_text(json.dumps(rec, indent=1), encoding="utf-8")
        print("written:", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

