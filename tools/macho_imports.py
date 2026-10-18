#!/usr/bin/env python3
"""Bounded thin little-endian Mach-O external undefined-symbol inventory."""
import argparse
import json
from pathlib import Path
import struct


def parse_bytes(data):
    def unpack(fmt, offset):
        size = struct.calcsize(fmt)
        if offset < 0 or offset + size > len(data):
            raise ValueError('truncated Mach-O structure')
        return struct.unpack_from(fmt, data, offset)

    magic, = unpack('<I', 0)
    if magic not in (0xfeedfacf, 0xfeedface):
        raise ValueError('only thin little-endian Mach-O supported')
    is64 = magic == 0xfeedfacf
    header_size, entry_size, alignment = (32, 16, 8) if is64 else (28, 12, 4)
    header = unpack('<8I' if is64 else '<7I', 0)
    ncmds, sizeofcmds = header[4:6]
    end = header_size + sizeofcmds
    if end > len(data) or ncmds > sizeofcmds // 8:
        raise ValueError('invalid load command region')
    offset, symtab = header_size, None
    for _ in range(ncmds):
        if offset + 8 > end:
            raise ValueError('command header outside declared region')
        cmd, size = unpack('<II', offset)
        if size < 8 or size % alignment or offset + size > end:
            raise ValueError('invalid command size')
        if cmd == 2:
            if symtab is not None or size != 24:
                raise ValueError('duplicate/invalid LC_SYMTAB')
            symtab = unpack('<4I', offset + 8)
        offset += size
    if offset != end or symtab is None:
        raise ValueError('command count/size mismatch or missing LC_SYMTAB')
    symoff, count, stroff, strsize = symtab
    symend, strend = symoff + count * entry_size, stroff + strsize
    if (symoff < end or stroff < end or symend > len(data) or strend > len(data)
            or (count and strsize and symoff < strend and stroff < symend)):
        raise ValueError('symbol/string table outside file or overlapping')
    if not strsize or data[stroff] != 0:
        raise ValueError('invalid string table sentinel')
    imports = []
    for i in range(count):
        index, kind, sect, desc, value = unpack('<IBBHQ' if is64 else '<IBBHI', symoff+i*entry_size)
        if index >= strsize:
            raise ValueError('symbol name outside string table')
        start = stroff + index
        stop = data.find(b'\0', start, strend)
        if stop < 0:
            raise ValueError('unterminated symbol name')
        name = data[start:stop].decode('utf-8', errors='strict')
        # N_STAB debug, non-N_UNDF, non-N_EXT and common definitions are not imports.
        if kind & 0xe0 or kind & 0x0e or not kind & 1 or value:
            continue
        if sect != 0 or not name:
            raise ValueError('invalid external undefined entry')
        if name in imports:
            raise ValueError('duplicate external undefined symbol')
        imports.append(name)
    return imports


def parse(path):
    return parse_bytes(Path(path).read_bytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary', type=Path)
    parser.add_argument('--grep')
    parser.add_argument('--json', type=Path)
    args = parser.parse_args()
    names = parse(args.binary)
    shown = [n for n in names if not args.grep or args.grep in n]
    print(f'{args.binary}: {len(names)} undefined symbols, {len(shown)} shown')
    for name in shown[:40]:
        print('  '+name)
    if args.json:
        args.json.write_text(json.dumps({'binary': str(args.binary), 'undefined': names}, indent=1)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
