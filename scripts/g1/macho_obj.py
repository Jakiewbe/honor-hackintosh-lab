#!/usr/bin/env python3
"""Minimal read-only Mach-O (thin, x86_64, little-endian) reader for G1 rebuild comparison: sections, symbols,
per-section relocations, and function byte ranges in __TEXT,__text. Works for MH_OBJECT (.o) and linked images
(kext bundle). No third-party dependencies."""
import struct
from pathlib import Path

MH_MAGIC_64 = 0xFEEDFACF
LC_SEGMENT_64, LC_SYMTAB = 0x19, 0x2
N_STAB, N_TYPE, N_EXT, N_SECT, N_UNDF = 0xE0, 0x0E, 0x01, 0x0E, 0x00


class MachO:
    def __init__(self, path):
        self.path = Path(path)
        b = self.data = self.path.read_bytes()
        magic, _, _, self.filetype, ncmds, _, _, _ = struct.unpack_from("<IiiIIIII", b, 0)
        if magic != MH_MAGIC_64:
            raise ValueError(f"{path}: not a thin 64-bit Mach-O (magic 0x{magic:x})")
        self.sections = []  # dicts: name, addr, size, offset, reloff, nreloc
        symtab = None
        off = 32
        for _ in range(ncmds):
            cmd, size = struct.unpack_from("<II", b, off)
            if cmd == LC_SEGMENT_64:
                nsects = struct.unpack_from("<I", b, off + 64)[0]
                s = off + 72
                for _ in range(nsects):
                    sect = b[s:s + 16].rstrip(b"\0").decode()
                    seg = b[s + 16:s + 32].rstrip(b"\0").decode()
                    addr, ssize, soff, _, reloff, nreloc = struct.unpack_from("<QQIIII", b, s + 32)
                    self.sections.append({"name": f"{seg},{sect}", "addr": addr, "size": ssize, "offset": soff,
                                          "reloff": reloff, "nreloc": nreloc})
                    s += 80
            elif cmd == LC_SYMTAB:
                symtab = struct.unpack_from("<IIII", b, off + 8)
            off += size
        self.symbols = []  # (name, ntype, sect_index_1based, value)
        if symtab:
            symoff, nsyms, stroff, _ = symtab
            for i in range(nsyms):
                strx, ntype, sect, _, value = struct.unpack_from("<IBBhQ", b, symoff + 16 * i)
                end = b.index(b"\0", stroff + strx)
                self.symbols.append((b[stroff + strx:end].decode("latin-1"), ntype, sect, value))

    def section_index(self, name):
        for i, s in enumerate(self.sections):
            if s["name"] == name:
                return i + 1
        return None

    def defined(self):
        return [(n, t, s, v) for n, t, s, v in self.symbols if not t & N_STAB and (t & N_TYPE) == N_SECT]

    def undefined(self):
        return {n for n, t, s, v in self.symbols if not t & N_STAB and (t & N_TYPE) == N_UNDF and t & N_EXT}

    def relocation_mask(self, sect_index):
        """Byte offsets (relative to section start) covered by relocations; empty for linked images."""
        s = self.sections[sect_index - 1]
        mask = set()
        for i in range(s["nreloc"]):
            addr, info = struct.unpack_from("<iI", self.data, s["reloff"] + 8 * i)
            if addr < 0:  # scattered relocation (not used on x86_64)
                continue
            length = 1 << ((info >> 25) & 3)
            mask.update(range(addr, addr + length))
        return mask

    def functions(self):
        """name -> (bytes, masked offsets relative to function start) for named symbols in __TEXT,__text.
        Assembler-local labels (l*/L*/ltmp*) are skipped; a function ends at the next named symbol."""
        idx = self.section_index("__TEXT,__text")
        if idx is None:
            return {}
        s = self.sections[idx - 1]
        named = sorted({(v, n) for n, t, sec, v in self.defined()
                        if sec == idx and not n.startswith(("l", "L", "ltmp"))})
        mask = self.relocation_mask(idx)
        out = {}
        # Aliases at one address share a body; none may truncate another to zero bytes.
        addresses = sorted({v for v, _ in named})
        ends = dict(zip(addresses, addresses[1:] + [s["addr"] + s["size"]]))
        for v, n in named:
            start, end = v - s["addr"], ends[v] - s["addr"]
            if end <= start:
                continue
            body = self.data[s["offset"] + start:s["offset"] + end]
            out.setdefault(n, []).append((body, {m - start for m in mask if start <= m < end}))
        return out
