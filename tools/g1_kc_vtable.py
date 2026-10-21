#!/usr/bin/env python3
"""Dump a kernel-collection member's C++ vtable slots, resolved to symbol names.

Read-only observation. It answers one question the headers cannot: which virtual methods, in which
order, the running macOS actually carries for a class. Nothing is loaded or executed.

Usage: g1_kc_vtable.py <collection.kc> <bundle-id> <Class> [<Class> ...]
"""
import argparse
import json
import mmap
import struct
from pathlib import Path

import g1_kc8 as kc


def all_symbols(raw, member, limit=2_000_000):
    """Every symbol in the member's table, address -> name (first wins)."""
    table = member['symtab']
    if not table or not table['nsyms']:
        raise ValueError('member has no symbol table')
    if table['nsyms'] > limit:
        raise ValueError('unreasonable symbol count')
    strings = kc.bounded(raw, table['stroff'], table['strsize'])
    by_value = {}
    for i in range(table['nsyms']):
        _, ntype, section, _, value = struct.unpack('<IBBHQ', kc.bounded(raw, table['symoff'] + i * 16, 16))
        index = struct.unpack('<I', kc.bounded(raw, table['symoff'] + i * 16, 4))[0]
        if index >= len(strings):
            continue
        end = strings.find(b'\0', index)
        if end < 0:
            continue
        name = strings[index:end].decode('utf-8', errors='replace')
        if (ntype & 0x0e) == 0x0e and value:
            by_value.setdefault(value, name)
    return by_value


def vtable(raw, member, by_value, class_name):
    mangled = '__ZTV%d%s' % (len(class_name), class_name)
    address = None
    for value, name in by_value.items():
        if name == mangled:
            address = value
            break
    if address is None:
        return dict(class_name=class_name, mangled=mangled, status='VTABLE_SYMBOL_ABSENT')
    section = next((s for s in member['sections'] if s['address'] <= address < s['address'] + s['size']), None)
    if not section:
        return dict(class_name=class_name, mangled=mangled, status='VTABLE_OUTSIDE_SECTION')
    # A vtable has no terminator. Its extent is the distance to the next symbol in the same section;
    # that gives an exact slot count, which is what decides whether a header layout matches the image.
    following = sorted(v for v in by_value
                       if v > address and section['address'] <= v < section['address'] + section['size'])
    extent_end = following[0] if following else section['address'] + section['size']
    slot_bytes = extent_end - address - 16
    if slot_bytes < 0 or slot_bytes % 8:
        return dict(class_name=class_name, mangled=mangled, status='VTABLE_EXTENT_UNCLEAR',
                    address=hex(address), next_symbol=hex(extent_end))
    slots = []
    for index in range(slot_bytes // 8):
        pointer = struct.unpack('<Q', raw[address + 16 + index * 8 - (section['address'] - section['offset']):
                                     address + 16 + index * 8 - (section['address'] - section['offset']) + 8])[0]
        slots.append(dict(slot=index, address=hex(pointer), symbol=by_value.get(pointer, 'UNRESOLVED')))
    return dict(class_name=class_name, mangled=mangled, status='VTABLE_DUMPED', address=hex(address),
                next_symbol=hex(extent_end), slot_count=len(slots), slots=slots)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('collection', type=Path)
    parser.add_argument('bundle', help='fileset entry id, for example com.apple.iokit.IOAcceleratorFamily2')
    parser.add_argument('classes', nargs='+')
    args = parser.parse_args()

    with args.collection.open('rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
        before = __import__('hashlib').sha256(raw).hexdigest()
        outer = kc.header(raw)
        if outer['filetype'] != 12:
            raise SystemExit('not a MH_FILESET collection')
        entries = [e for e in outer['entries'] if e['id'] == args.bundle]
        if len(entries) != 1:
            raise SystemExit('expected exactly one fileset entry for %s, found %d' % (args.bundle, len(entries)))
        member = kc.header(raw, entries[0]['fileoff'])
        by_value = all_symbols(raw, member)
        result = dict(collection=str(args.collection), bundle=args.bundle,
                      sha256=before, symbols=len(by_value),
                      classes=[vtable(raw, member, by_value, c) for c in args.classes])
        if __import__('hashlib').sha256(raw).hexdigest() != before:
            raise SystemExit('collection changed during observation')
    print(json.dumps(result, indent=1))


if __name__ == '__main__':
    main()
