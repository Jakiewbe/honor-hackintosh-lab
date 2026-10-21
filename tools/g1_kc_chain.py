#!/usr/bin/env python3
"""Decode kernel-collection vtable slots (LC_DYLD_CHAINED_FIXUPS) and resolve them to symbols.

An x86_64 kernel collection uses DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE (11): a 64-bit entry with
target:30, cacheLevel:2, diversity:16, addrDiv:1, key:2, next:12, isAuth:1, and a 4-byte chain
stride. dyld_info asserts on the 365 MB collection, so the chain is walked here directly.

Read-only. Usage: g1_kc_chain.py <collection.kc> <bundle-id> <Class> [...]
"""
import argparse
import json
import mmap
import struct

import g1_kc8 as kc

CHAINED = 0x80000034
KERNEL_CACHE = 11
PTR_64 = 2
PTR_64_OFFSET = 6
STRIDE = {KERNEL_CACHE: 4, PTR_64: 4, PTR_64_OFFSET: 4}


def chained_header(raw, mach):
    for command in mach['load_commands']:
        if int(command['cmd'], 16) != CHAINED:
            continue
        data = raw[command['offset']:command['offset'] + command['bytes']]
        dataoff, datasize = struct.unpack_from('<II', data, 8)
        if dataoff == 0 or datasize < 28:
            return None
        head = raw[dataoff:dataoff + datasize]
        version, starts, imports_offset, symbols_offset, count, ifmt, sfmt = struct.unpack_from('<7I', head, 0)
        return dict(base=dataoff, size=datasize, version=version, starts=starts,
                    imports_offset=imports_offset, symbols_offset=symbols_offset,
                    imports_count=count, imports_format=ifmt, symbols_format=sfmt)
    return None


def segments(raw, chain):
    start = chain['base'] + chain['starts']
    count = struct.unpack_from('<I', raw, start)[0]
    if count > 64:
        raise ValueError('unreasonable segment count %d' % count)
    out = []
    for i in range(count):
        offset = struct.unpack_from('<I', raw, start + 4 + 4 * i)[0]
        if not offset:
            out.append(None)
            continue
        address = start + offset
        size = struct.unpack_from('<I', raw, address)[0]
        page_size = struct.unpack_from('<H', raw, address + 4)[0]
        pointer_format = struct.unpack_from('<H', raw, address + 6)[0]
        segment_offset = struct.unpack_from('<Q', raw, address + 8)[0]
        page_count = struct.unpack_from('<H', raw, address + 20)[0]
        pages = [struct.unpack_from('<H', raw, address + 22 + 2 * j)[0] for j in range(page_count)]
        out.append(dict(size=size, page_size=page_size, pointer_format=pointer_format,
                        segment_offset=segment_offset, page_count=page_count, pages=pages))
    return out


def _u64(raw, position):
    if position < 0 or position + 8 > len(raw):
        return None
    return struct.unpack_from('<Q', raw, position)[0]


def walk(raw, info, segment_base, target_filepos):
    """Try the plausible page_start/stride combinations and return the first that reaches the slot."""
    page_size = info['page_size']
    if not page_size:
        return None
    relative = target_filepos - segment_base
    if relative < 0:
        return None
    page = relative // page_size
    if page >= info['page_count']:
        return None
    start = info['pages'][page]
    if start == 0xFFFF:
        return None
    stride = STRIDE.get(info['pointer_format'], 4)
    for first in (start, start * 4, 0):
        position = segment_base + page * page_size + first
        for _ in range(4096):
            value = _u64(raw, position)
            if value is None:
                break
            nxt = (value >> 51) & 0xFFF
            if info['pointer_format'] == KERNEL_CACHE:
                target = value & 0x3FFFFFFF
                authenticated = value >> 63
            else:
                target = value & 0xFFFFFFFFF
                authenticated = 0
            if position == target_filepos:
                return dict(target=target, first_byte=first, stride=stride,
                            authenticated=int(authenticated))
            if nxt == 0:
                break
            position += nxt * stride
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
    parser.add_argument('--slots', type=int, default=64)
    args = parser.parse_args()

    with open(args.collection, 'rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
        outer = kc.header(raw)
        entries = [e for e in outer['entries'] if e['id'] == args.bundle]
        if len(entries) != 1:
            raise SystemExit('expected one fileset entry for %s' % args.bundle)
        member_fileoff = entries[0]['fileoff']
        member = kc.header(raw, member_fileoff)
        chain = chained_header(raw, member) or chained_header(raw, outer)
        if not chain:
            raise SystemExit('no LC_DYLD_CHAINED_FIXUPS')
        starts = segments(raw, chain)
        names = symbols(raw, member)
        report = dict(collection=args.collection, bundle=args.bundle, member_fileoff=member_fileoff,
                      pointer_formats=sorted({s['pointer_format'] for s in starts if s}),
                      member_segments=[{k: s[k] for k in ('name','vmaddr','vmsize','fileoff','filesize')}
                                       for s in member['segments']],
                      chain_segments=[{k: s[k] for k in ('segment_offset','page_size','page_count')}
                                      for s in starts if s],
                      classes=[])
        for cls in args.classes:
            mangled = '__ZTV%d%s' % (len(cls), cls)
            address = next((v for v, n in names.items() if n == mangled), None)
            if address is None:
                report['classes'].append(dict(class_name=cls, status='VTABLE_SYMBOL_ABSENT'))
                continue
            section = next((s for s in member['sections'] if s['address'] <= address < s['address'] + s['size']), None)
            vtable_section = dict(name=section['name'], segment=section['segment'], address=hex(section['address']),
                                  offset=section['offset'], size=section['size']) if section else None
            if not section:
                report['classes'].append(dict(class_name=cls, status='VTABLE_OUTSIDE_SECTION'))
                continue
            # member-relative offset to absolute file position
            delta = member_fileoff + section['offset'] - section['address']
            slots = []
            for index in range(args.slots):
                filepos = address + 16 + index * 8 + delta
                info = next((s for s in starts if s and s['segment_offset'] <= filepos - member_fileoff
                             < s['segment_offset'] + s['page_size'] * s['page_count']), None)
                if not info:
                    break
                decoded = walk(raw, info, member_fileoff + info['segment_offset'], filepos)
                if not decoded:
                    break
                slots.append(dict(slot=index, target=hex(decoded['target']),
                                  symbol=names.get(decoded['target'], 'UNRESOLVED'),
                                  first_byte=decoded['first_byte'], stride=decoded['stride']))
            report['classes'].append(dict(class_name=cls, vtable=hex(address), vtable_section=vtable_section,
                                          status='CHAIN_DECODED' if slots else 'CHAIN_FAILED',
                                          slots=slots))
        print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
