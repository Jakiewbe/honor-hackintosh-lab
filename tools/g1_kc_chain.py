#!/usr/bin/env python3
"""Decode chained-fixup vtable slots in a kernel collection and resolve them to symbol names.

Why this exists: raw vtable words in a kernel collection are not plain addresses; they are
dyld chained-fixup entries. dyld_info asserts on the 365 MB collection, so the chain is decoded
here directly from LC_DYLD_CHAINED_FIXUPS.

Read-only. Usage: g1_kc_chain.py <collection.kc> <bundle-id> <Class> [...]
"""
import argparse
import ctypes
import json
import mmap
import struct

import g1_kc8 as kc

CHAINED = 0x80000034
PTR_64 = 2
PTR_64_OFFSET = 6


def chained_header(raw, mach):
    for command in mach['load_commands']:
        if int(command['cmd'], 16) != CHAINED:
            continue
        data = raw[command['offset']:command['offset'] + command['bytes']]
        dataoff = struct.unpack_from('<I', data, 8)[0]
        size = struct.unpack_from('<I', data, 12)[0]
        if dataoff == 0 or size < 28:
            return None
        head = raw[dataoff:dataoff + size]
        (fixups_version, starts_offset, imports_offset, symbols_offset,
         imports_count, imports_format, symbols_format) = struct.unpack_from('<7I', head, 0)
        return dict(base=dataoff, size=size, version=fixups_version, starts=starts_offset,
                    imports_offset=imports_offset, symbols_offset=symbols_offset,
                    imports_count=imports_count, imports_format=imports_format,
                    symbols_format=symbols_format, head=head)
    return None


def segment_starts(head, raw, base):
    seg_count = struct.unpack_from('<I', head, 0)[0]
    offsets = [struct.unpack_from('<I', head, 4 + 4 * i)[0] for i in range(seg_count)]
    out = []
    for offset in offsets:
        if not offset:
            out.append(None)
            continue
        address = base + offset
        size = struct.unpack_from('<I', raw, address)[0]
        page_size = struct.unpack_from('<H', raw, address + 4)[0]
        pointer_format = struct.unpack_from('<H', raw, address + 6)[0]
        segment_offset = struct.unpack_from('<Q', raw, address + 8)[0]
        max_valid = struct.unpack_from('<I', raw, address + 16)[0]
        page_count = struct.unpack_from('<H', raw, address + 20)[0]
        pages = [struct.unpack_from('<H', raw, address + 22 + 2 * i)[0] for i in range(page_count)]
        out.append(dict(size=size, page_size=page_size, pointer_format=pointer_format,
                        segment_offset=segment_offset, max_valid=max_valid,
                        page_count=page_count, pages=pages))
    return out


def decode_chain(raw, starts, member, target_filepos):
    """Return the decoded target of the pointer stored at target_filepos, or None."""
    for index, info in enumerate(starts):
        if not info or info['pointer_format'] not in (PTR_64, PTR_64_OFFSET):
            continue
        start = info['segment_offset']
        end = start + info['page_size'] * info['page_count']
        if not (start <= target_filepos < end):
            continue
        page = (target_filepos - start) // info['page_size']
        page_start = info['pages'][page]
        if page_start in (0xFFFF, 0x8000):
            return None
        position = start + page * info['page_size'] + page_start
        for _ in range(512):
            if position < 0 or position + 8 > len(raw):
                return None
            value = struct.unpack_from('<Q', raw, position)[0]
            bind = value >> 63
            nxt = (value >> 51) & 0xFFF
            target = value & 0xFFFFFFFFF
            if bind:
                return None
            if position == target_filepos:
                return dict(target=target, format=info['pointer_format'], slot_offset=position)
            if nxt == 0:
                return None
            position += nxt * 4 if info['pointer_format'] == PTR_64 else nxt * 8
    return None


def symbols(raw, member):
    table = member['symtab']
    if not table or not table['nsyms']:
        return {}
    strings = kc.bounded(raw, table['stroff'], table['strsize'])
    by_value = {}
    for i in range(table['nsyms']):
        position = table['symoff'] + i * 16
        index, ntype, section, _, value = struct.unpack('<IBBHQ', kc.bounded(raw, position, 16))
        if index >= len(strings):
            continue
        end = strings.find(b'\0', index)
        if end < 0:
            continue
        name = strings[index:end].decode('utf-8', errors='replace')
        if value:
            by_value.setdefault(value, name)
    return by_value


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('collection')
    parser.add_argument('bundle')
    parser.add_argument('classes', nargs='+')
    args = parser.parse_args()

    with open(args.collection, 'rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
        outer = kc.header(raw)
        entries = [e for e in outer['entries'] if e['id'] == args.bundle]
        if len(entries) != 1:
            raise SystemExit('expected one fileset entry')
        member = kc.header(raw, entries[0]['fileoff'])
        member_chain = chained_header(raw, member)
        outer_chain = chained_header(raw, outer)
        diagnostics = {}
        for label, chain in (('member', member_chain), ('outer', outer_chain)):
            if not chain:
                diagnostics[label] = dict(present=False)
                continue
            seg_count = struct.unpack_from('<I', chain['head'], 0)[0] if chain['size'] >= 4 else -1
            offsets = [struct.unpack_from('<I', chain['head'], 4 + 4 * i)[0]
                       for i in range(min(seg_count, 8))] if seg_count > 0 else []
            diagnostics[label] = dict(present=True, dataoff=chain['base'], datasize=chain['size'],
                                      version=chain['version'], starts=chain['starts'],
                                      seg_count=seg_count, first_offsets=offsets)
        chain = member_chain or outer_chain
        if not chain:
            raise SystemExit('no LC_DYLD_CHAINED_FIXUPS')
        starts = segment_starts(chain['head'], raw, chain['base'])
        names = symbols(raw, member)
        report = dict(collection=args.collection, bundle=args.bundle,
                      diagnostics=diagnostics,
                      pointer_formats=sorted({s['pointer_format'] for s in starts if s}),
                      classes=[])
        for cls in args.classes:
            mangled = '__ZTV%d%s' % (len(cls), cls)
            address = next((v for v, n in names.items() if n == mangled), None)
            if address is None:
                report['classes'].append(dict(class_name=cls, status='VTABLE_SYMBOL_ABSENT'))
                continue
            section = next((s for s in member['sections'] if s['address'] <= address < s['address'] + s['size']), None)
            if not section:
                report['classes'].append(dict(class_name=cls, status='VTABLE_OUTSIDE_SECTION'))
                continue
            base_offset = section['offset'] - section['address']
            slots = []
            for index in range(0, 64):
                filepos = address + 16 + index * 8 + base_offset
                decoded = decode_chain(raw, starts, member, filepos)
                if not decoded:
                    break
                slots.append(dict(slot=index, target=hex(decoded['target']),
                                  symbol=names.get(decoded['target'], 'UNRESOLVED')))
            report['classes'].append(dict(class_name=cls, status='CHAIN_DECODED',
                                          slots=slots))
        print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
