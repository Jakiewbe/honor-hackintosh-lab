#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Dependency survey for the translation units that define a set of symbols.

Input: the JSON produced by tools/find-symbol-defs.py (symbol -> [file:line, ...]).
For every defining file it reports: category, line count, includes that look Linux/Unix specific,
whether the file uses the RM runtime entry macro, and whether it mentions the altstack switch.

Usage: python tools/dep-survey.py symbol-definitions.json --root <ogkm> [--json out.json]
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

LINUXISH = re.compile(r'#\s*include\s*[<"]([^">]+)[">]')
INTERESTING = ("linux", "asm/", "sys/", "kthread", "workqueue", "conftest", "nv-linux", "nv-freebsd",
               "os-interface", "nvkms-os-interface", "nv-ioctl", "nv-mem", "nv-pci")


def main():
    src = Path(sys.argv[1])
    root = Path(sys.argv[sys.argv.index("--root") + 1])
    out = None
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])

    data = json.loads(src.read_text(encoding="utf-8"))
    files = {}
    for symbol, hits in data["found"].items():
        for h in hits:
            rel = h.rsplit(":", 1)[0]
            files.setdefault(rel, []).append(symbol)

    rows = []
    for rel, syms in sorted(files.items()):
        p = root / rel
        if not p.exists():
            rows.append({"file": rel, "symbols": syms, "error": "missing on disk"})
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        incs = [m.group(1) for m in LINUXISH.finditer(text)]
        linuxish = sorted({i for i in incs if any(k in i for k in INTERESTING)})
        rows.append({
            "file": rel,
            "symbols": syms,
            "lines": text.count("\n") + 1,
            "includes": len(incs),
            "linuxish_includes": linuxish,
            "uses_rm_runtime": "NV_ENTER_RM_RUNTIME" in text,
            "mentions_altstack": "__use_altstack__" in text,
        })

    print(f"{'file':58} {'lines':>6} {'inc':>4} {'linuxish':>8} {'RM_RT':>6} {'altstack':>8}")
    for r in rows:
        if "error" in r:
            print(f"{r['file'][:58]:58}  MISSING")
            continue
        print(f"{r['file'][:58]:58} {r['lines']:>6} {r['includes']:>4} "
              f"{len(r['linuxish_includes']):>8} {str(r['uses_rm_runtime']):>6} {str(r['mentions_altstack']):>8}")

    agg = Counter()
    for r in rows:
        if "error" in r:
            continue
        agg["files"] += 1
        if r["linuxish_includes"]:
            agg["with_linuxish_includes"] += 1
        if r["uses_rm_runtime"]:
            agg["using_NV_ENTER_RM_RUNTIME"] += 1
        if r["mentions_altstack"]:
            agg["mentioning_altstack"] += 1
    print("\naggregate:", dict(agg))
    if out:
        out.write_text(json.dumps({"root": str(root), "rows": rows, "aggregate": dict(agg)}, indent=1),
                       encoding="utf-8")
        print("written:", out)


if __name__ == "__main__":
    main()
