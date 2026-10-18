#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cross-check the official OGKM source inventory (`src/<component>/srcs.mk`) against the tree.

The complete-build gate derives its translation-unit list from `srcs.mk`, so the inventory is the build's
contract. This tool reads every module's file, then reports:

  * how many TUs the official list contains, per component;
  * which files exist on disk but are NOT listed (never compiled by the official build);
  * which listed files are missing on disk (the build would fail).

It never compiles anything and never claims a build result: it only says whether the inventory and the
tree agree, which is the precondition the gate assumes.

Usage:
    python tools/g1_srcs_inventory.py --nv <ogkm-root> [--json out.json]
"""
import argparse
import json
import re
import sys
from pathlib import Path

SRCS = re.compile(r"SRCS(?:_CXX)?\s*\+=\s*([A-Za-z0-9_./-]+\.(?:c|cpp))\s*$")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nv", required=True)
    ap.add_argument("--json")
    a = ap.parse_args()
    nv = Path(a.nv).resolve()

    components, problems = {}, []
    for mk in sorted(nv.glob("src/*/srcs.mk")):
        comp = mk.parent.name
        listed, bad = [], []
        for line in mk.read_text(encoding="utf-8", errors="replace").splitlines():
            s = line.strip()
            if not s or s.startswith("#") or s in ("SRCS ?=", "SRCS_CXX ?="):
                continue
            m = SRCS.match(s)
            if not m:
                bad.append(s)
                continue
            listed.append(m.group(1))
        base = mk.parent
        missing = [r for r in listed if not (base / r).is_file()]
        components[comp] = {"listed": len(listed), "missing_on_disk": missing,
                            "unsupported_syntax": bad, "files": listed}
        problems.extend(missing)
        problems.extend(f"{comp}: unsupported line: {b}" for b in bad)

    # srcs.mk entries are relative to src/<component>/, and may point outside it (e.g. ../common/...).
    # Resolve both sides to real paths before diffing, otherwise every ../ entry looks unlisted.
    listed_all = set()
    for c, v in components.items():
        base = nv / "src" / c
        for r in v["files"]:
            listed_all.add((base / r).resolve().as_posix())
    on_disk = {p.resolve().as_posix() for p in (nv / "src").rglob("*")
               if p.suffix in (".c", ".cpp") and "srcs.mk" not in p.name}
    extra = sorted(on_disk - listed_all)

    total = sum(v["listed"] for v in components.values())
    print(f"components: {len(components)}; official TUs: {total}")
    for c, v in sorted(components.items()):
        flag = "" if not (v["missing_on_disk"] or v["unsupported_syntax"]) else "  <-- PROBLEM"
        print(f"  {c:24} {v['listed']:5}{flag}")
    print(f"on disk (src/**/*.c|cpp): {len(on_disk)}; listed: {len(listed_all)}; "
          f"on disk but not listed: {len(extra)}")
    if extra:
        print("  not listed sample:", extra[:8])
    if problems:
        print("problems:", problems[:8])
    if a.json:
        Path(a.json).write_text(json.dumps({"official_total": total, "components":
                                            {c: {k: v[k] for k in ("listed", "missing_on_disk", "unsupported_syntax")}
                                             for c, v in components.items()},
                                            "on_disk": len(on_disk), "not_listed": [x.replace(nv.as_posix()+"/","") for x in extra[:200]],
                                            "problems": problems[:50]}, indent=1), encoding="utf-8")
        print("written:", a.json)
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
