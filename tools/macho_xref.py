#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Find which functions reference an imported symbol in a linked Mach-O, without a disassembler.

A linked kext has no relocations left: a call to an imported symbol goes through a stub in
`__TEXT,__stubs`, whose entry is bound through the indirect symbol table. So the chain is

    call site (E8 rel32)  ->  stub  ->  symbol name

This tool resolves that chain: it maps every stub to its symbol, then scans `__TEXT,__text` for `call`
instructions whose computed target is one of the stubs, and reports the containing function (from the
symbol table) for the requested symbol.

Caveats, stated so the output is not over-read:
  * Only `call rel32` (0xE8) is recognised. Calls through a register or `__got` slot are invisible here.
  * A byte-level scan cannot know instruction boundaries, so a match is confirmed only by an exact
    target hit on the stub; false positives are still possible in data embedded in __text.
  * A function is attributed by the nearest preceding defined symbol; that symbol may be a local label.

Usage:
    python tools/macho_xref.py <binary> --symbol _ZN12IOUserClient4freeEv [--json out.json]
"""
import json
import struct
import sys
from pathlib import Path

LC_SEGMENT_64 = 0x19
LC_SYMTAB = 0x2
LC_DYSYMTAB = 0xB


def u32(d, o):
    return struct.unpack_from("<I", d, o)[0]


def parse(d):
    magic = u32(d, 0)
    if magic != 0xFEEDFACF:
        raise SystemExit(f"not a thin 64-bit Mach-O (magic 0x{magic:08x})")
    _, _, _, ncmds, _, _ = struct.unpack_from("<IiiIIi", d, 0)
    off = 32
    segments, symtab, dysymtab = [], None, None
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", d, off)
        if cmd == LC_SEGMENT_64:
            name = d[off + 8:off + 24].rstrip(b"\x00").decode("ascii", "replace")
            vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", d, off + 24)
            nsects = u32(d, off + 64)
            sect_off = off + 72
            sections = {}
            for _ in range(nsects):
                sname = d[sect_off:sect_off + 16].rstrip(b"\x00").decode("ascii", "replace")
                addr, size, offset = struct.unpack_from("<QQI", d, sect_off + 32)[0], \
                    struct.unpack_from("<Q", d, sect_off + 40)[0], u32(d, sect_off + 48)
                sections[sname] = {"addr": addr, "size": size, "offset": offset}
                sect_off += 80
            segments.append({"name": name, "vmaddr": vmaddr, "vmsize": vmsize,
                             "fileoff": fileoff, "filesize": filesize, "sections": sections})
        elif cmd == LC_SYMTAB:
            symtab = struct.unpack_from("<IIII", d, off + 8)
        elif cmd == LC_DYSYMTAB:
            vals = struct.unpack_from("<IIIIIIIIIIIIIIIIIIII", d, off + 8)
            # indirectsymoff, nindirectsyms are fields 12 and 13 (0-based) of dysymtab_command
            dysymtab = {"indirectsymoff": vals[12], "nindirectsyms": vals[13]}
        off += cmdsize
    if not symtab:
        raise SystemExit("no LC_SYMTAB")
    return segments, symtab, dysymtab


def symbols(d, symtab):
    symoff, nsyms, stroff, _ = symtab
    out = []
    for i in range(nsyms):
        p = symoff + i * 16
        n_strx, n_type, n_sect, n_desc, n_value = struct.unpack_from("<IBBHQ", d, p)
        # Keep STAB entries in place: the indirect symbol table indexes raw symtab entries, so dropping
        # them here would shift every later index and silently bind the wrong names.
        e = d.find(b"\x00", stroff + n_strx)
        name = d[stroff + n_strx:e].decode("utf-8", "replace")
        out.append({"name": name, "type": n_type, "sect": n_sect, "value": n_value,
                    "undef": (n_type & 0x0E) == 0})
    return out


def main():
    path = sys.argv[1]
    want = sys.argv[sys.argv.index("--symbol") + 1]
    d = Path(path).read_bytes()
    segments, symtab, dysymtab = parse(d)
    syms = symbols(d, symtab)
    by_name = {s["name"]: s for s in syms}

    # stub entries are 6 bytes on x86_64: jmp *disp32(%rip)
    stubs, got = {}, {}
    for seg in segments:
        for sname, sec in seg["sections"].items():
            if sname in ("__stubs", "__got", "__la_symbol_ptr"):
                base, count = sec["addr"], sec["size"] // 6 if sname == "__stubs" else sec["size"] // 8
                entries = {}
                if dysymtab:
                    ioff, nind = dysymtab["indirectsymoff"], dysymtab["nindirectsyms"]
                    for i in range(count):
                        idx = u32(d, ioff + 4 * (len(entries) + (sec["offset"] - sec["offset"]))) if False else None
                    # indirect entries are indexed by the section's reserved1
                    pass
                (stubs if sname == "__stubs" else got)[sname] = {"addr": base, "size": sec["size"]}

    # resolve stub -> symbol via the indirect table; reserved1 of the section gives the start index
    # (re-read the section header to get reserved1)
    sec_reserved = {}
    off = 32
    _, _, _, ncmds, _, _ = struct.unpack_from("<IiiIIi", d, 0)
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", d, off)
        if cmd == LC_SEGMENT_64:
            nsects = u32(d, off + 64)
            sect_off = off + 72
            for _ in range(nsects):
                sname = d[sect_off:sect_off + 16].rstrip(b"\x00").decode("ascii", "replace")
                reserved1 = u32(d, sect_off + 68)
                sec_reserved[sname] = reserved1
                sect_off += 80
        off += cmdsize

    stub_targets = {}
    if dysymtab and "__stubs" in stubs:
        ioff, nind = dysymtab["indirectsymoff"], dysymtab["nindirectsyms"]
        base = stubs["__stubs"]["addr"]
        start = sec_reserved.get("__stubs", 0)
        n = stubs["__stubs"]["size"] // 6
        for i in range(n):
            k = start + i
            if k >= nind:
                break
            si = u32(d, ioff + 4 * k)
            if si == 0x80000000 or si >= len(syms):
                continue
            stub_targets[base + i * 6] = syms[si]["name"]

    # kexts are fully bound: imports are usually reached as `call *__got(%rip)` rather than via a stub
    got_slots = {}
    if dysymtab and "__got" in got:
        ioff, nind = dysymtab["indirectsymoff"], dysymtab["nindirectsyms"]
        base = got["__got"]["addr"]
        start = sec_reserved.get("__got", 0)
        n = got["__got"]["size"] // 8
        for i in range(n):
            k = start + i
            if k >= nind:
                break
            si = u32(d, ioff + 4 * k)
            if si == 0x80000000 or si >= len(syms):
                continue
            got_slots[base + i * 8] = syms[si]["name"]

    stub_addr = [a for a, n in stub_targets.items() if n == want]
    got_addr = [a for a, n in got_slots.items() if n == want]
    if not stub_addr and got_addr:
        slot = got_addr[0]
        print(f"__got slot for {want} at 0x{slot:x}")
        text = next((s for seg in segments for nm, s in seg["sections"].items() if nm == "__text"), None)
        raw = d[text["offset"]:text["offset"] + text["size"]]
        funcs = sorted((s["value"], s["name"]) for s in syms
                       if not s["undef"] and text["addr"] <= s["value"] < text["addr"] + text["size"])
        hits = []
        for i in range(len(raw) - 6):
            # call qword ptr [rip+disp32]  ==  FF 15 disp32
            if raw[i] != 0xFF or raw[i + 1] != 0x15:
                continue
            disp = struct.unpack_from("<i", raw, i + 2)[0]
            target = text["addr"] + i + 6 + disp
            if target != slot:
                continue
            site = text["addr"] + i
            owner = None
            for v, nm in funcs:
                if v <= site:
                    owner = nm
                else:
                    break
            hits.append({"site": f"0x{site:x}", "caller": owner})
        print(f"call sites: {len(hits)}")
        for h in hits:
            print(f"  {h['site']}  in {h['caller']}")
        if "--json" in sys.argv:
            out = Path(sys.argv[sys.argv.index("--json") + 1])
            out.write_text(json.dumps({"symbol": want, "got_slot": f"0x{slot:x}", "hits": hits,
                                       "note": "FF 15 (call *rip-disp) scan only"}, indent=1), encoding="utf-8")
            print("written:", out)
        return 0
    if not stub_addr:
        print(f"symbol {want} has no __stubs entry (it may be reached through __got only)")
        for sname, info in got.items():
            print(f"  {sname}: {info['size']} bytes at 0x{info['addr']:x}")
        return 1
    stub = stub_addr[0]
    print(f"stub for {want} at 0x{stub:x}")

    text = next((s for seg in segments for nm, s in seg["sections"].items() if nm == "__text"), None)
    if not text:
        raise SystemExit("no __text")
    raw = d[text["offset"]:text["offset"] + text["size"]]
    funcs = sorted((s["value"], s["name"]) for s in syms
                   if not s["undef"] and text["addr"] <= s["value"] < text["addr"] + text["size"])

    hits = []
    for i in range(len(raw) - 5):
        if raw[i] != 0xE8:
            continue
        disp = struct.unpack_from("<i", raw, i + 1)[0]
        target = text["addr"] + i + 5 + disp
        if target == stub:
            site = text["addr"] + i
            owner = None
            for v, nm in funcs:
                if v <= site:
                    owner = nm
                else:
                    break
            hits.append({"site": f"0x{site:x}", "caller": owner})

    print(f"call sites: {len(hits)}")
    for h in hits:
        print(f"  {h['site']}  in {h['caller']}")
    if "--json" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--json") + 1])
        out.write_text(json.dumps({"symbol": want, "stub": f"0x{stub:x}", "hits": hits,
                                   "note": "E8 rel32 scan only; register/__got calls not visible"},
                                  indent=1), encoding="utf-8")
        print("written:", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
