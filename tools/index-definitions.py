#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a "symbol -> defining file" index for a source tree, then look up a list of names.

Single pass per file, two accepted definition shapes:
    TYPE  name(args)            - same line
    TYPE  name                  - name alone on its line, "(" on the next
Call sites are rejected because the text before the name must be a type-ish prefix that does not
contain '(' or '=' or '!' or ','.

Usage:
    python tools/index-definitions.py <tree> <names-file> [--json out.json]
"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

DEF_LINE = re.compile(r"^\s*[A-Za-z_][\w \t\*]*\b([A-Za-z_]\w{2,})\s*\(")
DEF_NAME_THEN_PAREN = re.compile(r"^\s*[A-Za-z_][\w \t\*]*\b([A-Za-z_]\w{2,})\s*$")
# A third shape: the type sits on the previous line and only the name is on this one.
NAME_ONLY = re.compile(r"^\s*([A-Za-z_]\w{2,})\s*$")


def main():
    tree = Path(sys.argv[1])
    names = {l.strip() for l in Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if l.strip()}
    out = Path(sys.argv[sys.argv.index("--json") + 1]) if "--json" in sys.argv else None

    index = defaultdict(list)
    files = 0
    for p in sorted(tree.rglob("*.c")):
        if ".git" in p.parts:
            continue
        files += 1
        try:
            lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        rel = p.relative_to(tree).as_posix()
        for i, line in enumerate(lines):
            m = DEF_LINE.match(line) or DEF_NAME_THEN_PAREN.match(line)
            name = m.group(1) if m else None
            if name is None:
                mo = NAME_ONLY.match(line)
                # name alone: accept only when the next line opens the parameter list and the previous
                # line is not a statement (a call site would not be followed by a fresh "(" line)
                if mo and i + 1 < len(lines) and lines[i + 1].lstrip().startswith("("):
                    prev = lines[i - 1].rstrip() if i else ""
                    if not prev.endswith((";", "{", ",", "=")):
                        name = mo.group(1)
            if name is None:
                continue
            # a name-then-paren signature must be followed by a line that starts with "("
            if m and DEF_NAME_THEN_PAREN.match(line) and not (i + 1 < len(lines) and lines[i + 1].lstrip().startswith("(")):
                continue
            if name in names:
                index[name].append(f"{rel}:{i + 1}")

    found = {k: v for k, v in index.items() if v}
    missing = sorted(names - set(found))
    defining_files = sorted({loc.rsplit(":", 1)[0] for v in found.values() for loc in v})

    print(f"scanned {files} .c files")
    print(f"{len(found)}/{len(names)} names resolved; {len(missing)} unresolved")
    print(f"distinct defining files: {len(defining_files)}")
    for f in defining_files[:20]:
        print("   ", f)
    if missing:
        print("unresolved sample:", missing[:10])
    if out:
        out.write_text(json.dumps({"symbols": found, "missing": missing,
                                   "defining_files": defining_files}, indent=1), encoding="utf-8")
        print("written:", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
