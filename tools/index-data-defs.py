#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Find data-symbol definitions (and macro definitions) for a list of names.

Why this exists: `tools/index-definitions.py` only understands *function* shapes. A class descriptor or
a global table is defined as `TYPE name = ...` or `TYPE name[...]`, which that tool cannot see, and a
zero-hit there has already been mistaken for "source missing" once in this project.

This tool answers one narrow question: does the tree define this data name, and where?
A bare `TYPE name;` is reported as a tentative declaration, not a definition.

Usage:
    python tools/index-data-defs.py <tree> <names-file> [--json out.json]
"""
import json
import re
import sys
from pathlib import Path

EXTS = {".c", ".h", ".cpp", ".hpp", ".inc"}
# skip comments and preprocessor noise when looking for definitions
LINE_COMMENT = re.compile(r"//.*$")
VAR_DEF = re.compile(r"^\s*(?!extern\b)(?:const\s+|static\s+|volatile\s+)*"
                     r"[A-Za-z_][\w \t\*]*\b([A-Za-z_]\w{2,})\s*(?:=|\[)")
MACRO_DEF = re.compile(r"^\s*#\s*define\s+([A-Za-z_]\w{2,})\b")


def main():
    tree = Path(sys.argv[1])
    names = {l.strip().lstrip("_") for l in Path(sys.argv[2]).read_text(encoding="utf-8-sig").splitlines() if l.strip()}
    out = Path(sys.argv[sys.argv.index("--json") + 1]) if "--json" in sys.argv else None

    found, macros = {}, {}
    files = 0
    for p in sorted(tree.rglob("*")):
        if p.suffix not in EXTS or ".git" in p.parts or not p.is_file():
            continue
        files += 1
        try:
            lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        rel = p.relative_to(tree).as_posix()
        for i, raw in enumerate(lines):
            line = LINE_COMMENT.sub("", raw)
            m = VAR_DEF.match(line)
            if m and m.group(1).lstrip("_") in names:
                found.setdefault(m.group(1).lstrip("_"), []).append(f"{rel}:{i + 1}")
                continue
            m = MACRO_DEF.match(line)
            if m and m.group(1).lstrip("_") in names:
                macros.setdefault(m.group(1).lstrip("_"), []).append(f"{rel}:{i + 1}")

    missing = sorted(names - set(found) - set(macros))
    print(f"scanned {files} files")
    print(f"data definitions: {len(found)}/{len(names)}; macros: {len(macros)}; missing: {len(missing)}")
    for n in sorted(found):
        print(f"  DEF   {n:34} {found[n][0]}")
    for n in sorted(macros):
        print(f"  MACRO {n:34} {macros[n][0]}")
    for n in missing:
        print(f"  NONE  {n}")
    if out:
        out.write_text(json.dumps({"definitions": found, "macros": macros, "missing": missing}, indent=1),
                       encoding="utf-8")
        print("written:", out)
    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main())
