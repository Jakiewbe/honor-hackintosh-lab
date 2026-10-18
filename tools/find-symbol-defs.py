#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Find C function definitions for a list of symbol names, robust to formatting.

Why this exists: three searches in a row mis-classified real definitions because they assumed a
definition looks like `TYPE name(` on one line. Real code also writes

    NV_STATUS NV_API_CALL rm_run_nano_timer_callback
    (
        nvidia_stack_t *sp, ...

so the matcher must work on a window of text, not a line, and must require a `{` after the parameter
list (a declaration ends with `;` and has no body).

Usage: python tools/find-symbol-defs.py <source-root> <names-file|--names a,b,c> [--json out.json]
Names are the C identifiers (no leading underscore); Mach-O adds that.
"""
import json
import re
import sys
from pathlib import Path


def iter_sources(root: Path, exts=(".c", ".h", ".cc", ".cpp")):
    for p in root.rglob("*"):
        if p.suffix in exts and p.is_file() and ".git" not in p.parts:
            yield p


def defs_for(text, name):
    """Yield (offset, snippet) for every definition of `name` in `text`."""
    out = []
    for m in re.finditer(r"\b" + re.escape(name) + r"\b", text):
        window = text[m.start(): m.start() + 600]
        # a definition: name, optionally newline, parameter list, then a brace before any semicolon
        line_start = text.rfind("\n", 0, m.start()) + 1
        prefix = text[line_start:m.start()]
        # reject call sites: the text before the name must be empty (name starts the line) or a type only
        if prefix.strip() and not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_ \t\*]*", prefix.strip()):
            continue
        if re.match(re.escape(name) + r"\s*\([^;{}]*\)\s*\{", window, re.S):
            out.append(m.start())
    return out


def main():
    root = Path(sys.argv[1])
    if sys.argv[2] == "--names":
        names = sys.argv[3].split(",")
    else:
        names = [l.strip() for l in Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if l.strip()]
    out_json = None
    if "--json" in sys.argv:
        out_json = Path(sys.argv[sys.argv.index("--json") + 1])

    sources = list(iter_sources(root))
    blobs = {}
    for p in sources:
        try:
            blobs[p] = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            pass

    found, missing = {}, []
    for name in names:
        hits = []
        for p, text in blobs.items():
            for off in defs_for(text, name):
                line = text.count("\n", 0, off) + 1
                hits.append(f"{p.relative_to(root).as_posix()}:{line}")
        if hits:
            found[name] = hits
        else:
            missing.append(name)

    for name in names:
        if name in found:
            print(f"{name:36} {found[name][0]}")
    print(f"\n{len(found)}/{len(names)} have a definition; missing: {missing or 'none'}\n"
          f"scanned {len(blobs)} files under {root}")
    if out_json:
        out_json.write_text(json.dumps({"root": str(root), "found": found, "missing": missing}, indent=1),
                            encoding="utf-8")
        print("written:", out_json)
    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main())
