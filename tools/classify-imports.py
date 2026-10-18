#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Classify the undefined (imported) symbols of a linked kext by who is expected to provide them.

Usage: python tools/classify-imports.py <nm -gU undefined file> [--json out.json]

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
CPP_RUNTIME = ("__cxa_", "__gxx_", "__Unwind", "_Znwm", "_ZdlPv", "_Znam", "_ZdaPv", "_ZSt")


GAPS = {"nvKms": "ogkm-nvkms", "nvKmsKapi": "ogkm-nvkms", "rm_": "ogkm-rm", "nvrm_": "nullmoth-internal"}


def classify(sym: str) -> str:
    s = sym.lstrip("_")
    for prefix, gap in GAPS.items():
        if s.startswith(prefix):
            return gap
    if any(s.startswith(p) for p in KERNEL_PREFIXES) or s.startswith(("kOS", "kernel_", "semaphore_", "vfs_", "vnode_", "vn_", "sysctl", "snprintf", "vsnprintf", "strcmp", "strlen", "strncmp", "memcmp", "memmove", "read_random", "page_size")):
        return "mach/kern"
    if s.startswith(CPP_RUNTIME):
        return "c++ runtime"
    m = re.match(r"ZN[KV]?(\d+)(\w+)", s)
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
    if re.match(r"Z(TV|TI|TS)\\d", s):
        return "iokit/libkern"
    if s.startswith("Z") or s.startswith("std"):
        return "c++ runtime"
    return "unclassified"


def main():
    path = Path(sys.argv[1])
    out = None
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
    syms = [l.strip() for l in path.read_text(encoding="utf-8", errors="replace").splitlines()
            if l.strip().startswith("_")]
    cats = Counter(classify(s) for s in syms)
    unknown = [s for s in syms if classify(s) == "unclassified"]
    rec = {"file": str(path), "symbols": len(syms), "categories": dict(cats),
           "unclassified": unknown[:50], "unclassified_count": len(unknown)}
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
