#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""List undefined (imported) symbols of a Mach-O or kext binary, without external tools.

A byte search for a symbol name proves nothing about whether it is an import: the name could live in
the string table, in debug data, or in a comment. This script walks the Mach-O load commands, reads
LC_SYMTAB and reports the nlist entries with N_UNDF set, which is what the loader must resolve.

Usage:
    python tools/macho_imports.py <binary> [--grep NAME] [--json out.json]
"""
import json
import struct
import sys
from pathlib import Path

MH_MAGIC_64 = 0xFEEDFACF
MH_MAGIC_32 = 0xFEEDFACE
N_UNDF = 0x0
N_STAB = 0xE0


def parse(path):
    data = Path(path).read_bytes()
    if len(data) < 32:
        raise SystemExit("file too small to be Mach-O")
    magic = struct.unpack_from("<I", data, 0)[0]
    if magic == MH_MAGIC_64:
        is64 = True
        header_size = 32
        _, _, _, ncmds, _, _ = struct.unpack_from("<IiiIIi", data, 0)
    elif magic == MH_MAGIC_32:
        is64 = False
        header_size = 28
        _, _, _, ncmds, _, _ = struct.unpack_from("<IiiIIi", data, 0)
    else:
        raise SystemExit(f"not a thin Mach-O (magic 0x{magic:08x}); fat binaries need splitting first")

    off = header_size
    symtab = None
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, off)
        if cmd == 0x2:  # LC_SYMTAB
            symtab = struct.unpack_from("<IIII", data, off + 8)
        off += cmdsize
        if cmdsize <= 0:
            break
    if symtab is None:
        raise SystemExit("no LC_SYMTAB")

    symoff, nsyms, stroff, strsize = symtab
    entry = 16 if is64 else 12
    undef = []
    for i in range(nsyms):
        p = symoff + i * entry
        if is64:
            n_strx, n_type, n_sect, n_desc, n_value = struct.unpack_from("<IBBHQ", data, p)
        else:
            n_strx, n_type, n_sect, n_desc, n_value = struct.unpack_from("<IBBHI", data, p)
        if n_type & N_STAB:
            continue
        if (n_type & 0x0E) != N_UNDF:
            continue
        start = stroff + n_strx
        end = data.find(b"\x00", start)
        name = data[start:end].decode("utf-8", "replace")
        if name:
            undef.append(name)
    return undef


def main():
    path = sys.argv[1]
    undef = parse(path)
    needle = None
    if "--grep" in sys.argv:
        needle = sys.argv[sys.argv.index("--grep") + 1]
    hits = [s for s in undef if needle in s] if needle else undef
    print(f"{path}: {len(undef)} undefined symbols, {len(hits)} shown")
    for s in hits[:40]:
        print("  ", s)
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
        out.write_text(json.dumps({"binary": path, "undefined": undef}, indent=1), encoding="utf-8")
        print("written:", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
