#!/usr/bin/env python3
"""Bounded, per-class KC slot observations; never export or complete ABI proof."""
import argparse
import hashlib
import json
import mmap
import os
from pathlib import Path
import struct

import g1_kc8 as kc

CLASSES = ('IOAccelSurface', 'IOAccelGLContext2', 'IOAccelLegacyDisplayPipe', 'IOAccelLegacyDisplayMachine')
BUNDLE = 'com.apple.iokit.IOAcceleratorFamily2'


def symbols(raw, member):
    table = member['symtab']
    if not table or table['nsyms'] > 2_000_000:
        raise ValueError('absent or excessive member symbol table')
    strings = kc.bounded(raw, table['stroff'], table['strsize'])
    rows = []
    for i in range(table['nsyms']):
        pos = table['symoff']+i*16
        index, typ, sect, desc, value = struct.unpack('<IBBHQ', kc.bounded(raw, pos, 16))
        if index >= len(strings) or strings.find(b'\0', index) < 0:
            raise ValueError('invalid member symbol string')
        if typ & 0xe0 or typ & 0x0e != 0x0e:
            continue
        if not 1 <= sect <= len(member['sections']):
            raise ValueError('invalid member symbol section')
        sec = member['sections'][sect-1]
        if not sec['address'] <= value < sec['address']+sec['size']:
            raise ValueError('member symbol outside section')
        rows.append(dict(name=kc.zstring(strings[index:]), value=value, section=sect,
                         nlist_offset=pos, n_type=typ))
    return rows


def class_observation(raw, member, rows, name):
    candidates = [r for r in rows if r['name'] == '__ZTV'+str(len(name))+name]
    addresses = {r['value'] for r in candidates}
    if len(addresses) != 1:
        return dict(class_name=name, status='VTABLE_ADDRESS_ABSENT_OR_AMBIGUOUS')
    row = candidates[0]; address = row['value']; sec = member['sections'][row['section']-1]
    following = sorted({r['value'] for r in rows if r['section'] == row['section'] and r['value'] > address})
    end = following[0] if following else sec['address']+sec['size']
    # Next named definition is a conservative upper bound, not proof that all intermediate words
    # are primary vtable slots. Never extend into another named object or reinterpret its indices.
    count = (end-address-16)//8
    if end-address < 16 or (end-address-16) % 8 or count > 4096:
        return dict(class_name=name, status='VTABLE_EXTENT_UNCLEAR', address=hex(address), upper_bound=hex(end))
    by_value = {}
    for record in rows:
        by_value.setdefault(record['value'], []).append(record)
    slots = []
    for index in range(count):
        position = sec['offset']+address+16+index*8-sec['address']
        word = struct.unpack('<Q', kc.bounded(raw, position, 8))[0]
        target = word & 0x3fffffff
        matches = by_value.get(target, [])
        slots.append(dict(slot_relative_to_class=index, file_offset=position, raw_word=hex(word),
            target30_candidate=hex(target), cache_level=(word >> 30) & 3,
            definition_candidates=matches,
            resolution='TARGET30_MATCHES_MEMBER_NLIST' if matches else 'UNRESOLVED_NOT_ZERO'))
    return dict(class_name=name, status='BOUNDED_RAW_SLOT_OBSERVATION_NOT_FULL_LAYOUT',
        address=hex(address), vtable_symbol_records=candidates, section=sec,
        upper_bound=hex(end), boundary='NEXT_NAMED_DEFINITION_UPPER_BOUND',
        slots=slots, member_offsets='UNVERIFIED', calling_convention='UNVERIFIED', exports='UNVERIFIED')


def observe(path):
    with path.open('rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
        before = hashlib.sha256(raw).hexdigest()
        outer = kc.header(raw)
        if outer['filetype'] != 12:
            raise ValueError('expected MH_FILESET')
        entries = [e for e in outer['entries'] if e['id'] == BUNDLE]
        if len(entries) != 1:
            raise ValueError('family member absent or ambiguous')
        member = kc.header(raw, entries[0]['fileoff'])
        records = symbols(raw, member)
        result = dict(collection=str(path), collection_sha256=before, collection_bytes=len(raw),
            member_entry=entries[0], member_uuid=member['uuid'], bundle=BUNDLE,
            parser_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            source_commit=os.environ.get('GITHUB_SHA'), source_run=os.environ.get('GITHUB_RUN_ID'),
            pointer_interpretation='FORMAT11_TARGET30_CANDIDATE_ONLY_NOT_VALIDATED_CHAIN_WALK',
            classes=[class_observation(raw, member, records, c) for c in CLASSES],
            full_abi='UNVERIFIED', exports='UNVERIFIED', device='NO_GO')
        if hashlib.sha256(raw).hexdigest() != before:
            raise ValueError('collection changed during observation')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('collection', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    result = observe(args.collection)
    args.out.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
