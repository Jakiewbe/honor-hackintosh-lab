#!/usr/bin/env python3
"""Read-only Intel KC member/symbol observation, never loader or ABI acceptance."""
import argparse
import hashlib
import json
import mmap
import os
from pathlib import Path
import platform
import struct

from g1_target_providers import command, write

TARGETS = {
    'com.apple.iokit.IOPCIFamily': [
        '__ZN11IOPCIDevice19extendedConfigRead8Ey',
        '__ZN11IOPCIDevice20extendedConfigRead16Ey',
        '__ZN11IOPCIDevice20extendedConfigRead32Ey',
        '__ZN11IOPCIDevice20extendedConfigWrite8Eyh',
        '__ZN11IOPCIDevice21extendedConfigWrite16Eyt',
        '__ZN11IOPCIDevice21extendedConfigWrite32Eyj',
        '__ZN11IOPCIDevice9metaClassE'],
    'com.apple.iokit.IOACPIFamily': ['__ZN20IOACPIPlatformDevice9metaClassE']}


def bounded(raw, offset, size):
    if offset < 0 or size < 0 or offset+size > len(raw):
        raise ValueError('Mach-O range outside collection')
    return raw[offset:offset+size]


def zstring(raw):
    return raw.split(b'\0', 1)[0].decode('utf-8', errors='strict')


def header(raw, offset=0):
    magic, cpu, subtype, kind, ncmds, cmdsize, flags, reserved = struct.unpack(
        '<8I', bounded(raw, offset, 32))
    if magic != 0xfeedfacf or cpu != 0x01000007:
        raise ValueError('only thin little-endian x86_64 Mach-O supported')
    if ncmds > 65536 or cmdsize > 32*1024*1024:
        raise ValueError('unreasonable load command count/size')
    bounded(raw, offset+32, cmdsize)
    position, end = offset+32, offset+32+cmdsize
    commands, sections, segments, entries, uuids, symtabs = [], [], [], [], [], []
    for _ in range(ncmds):
        cmd, size = struct.unpack('<II', bounded(raw, position, 8))
        if size < 8 or size % 8 or position+size > end:
            raise ValueError('invalid load command bounds')
        data = bounded(raw, position, size)
        commands.append({'cmd': hex(cmd), 'offset': position, 'bytes': size})
        if cmd == 0x19:
            if size < 72:
                raise ValueError('truncated segment')
            _, _, name, vmaddr, vmsize, fileoff, filesize, maxp, initp, nsects, sflags = struct.unpack('<II16sQQQQIIII', data[:72])
            if size != 72+80*nsects:
                raise ValueError('segment section size mismatch')
            segment = {'name': zstring(name), 'vmaddr': vmaddr, 'vmsize': vmsize,
                'fileoff': fileoff, 'filesize': filesize, 'initprot': initp}
            segments.append(segment)
            for i in range(nsects):
                sec = struct.unpack('<16s16sQQIIIIIIII', data[72+80*i:152+80*i])
                sections.append({'ordinal': len(sections)+1, 'name': zstring(sec[0]),
                    'segment': zstring(sec[1]), 'address': sec[2], 'size': sec[3],
                    'offset': sec[4], 'flags': sec[8]})
        elif cmd == 0x1b:
            if size != 24:
                raise ValueError('invalid UUID command')
            uuids.append(data[8:24].hex())
        elif cmd == 2:
            if size != 24:
                raise ValueError('invalid symtab command')
            symoff, nsyms, stroff, strsize = struct.unpack('<4I', data[8:24])
            symtabs.append({'symoff': symoff, 'nsyms': nsyms, 'stroff': stroff, 'strsize': strsize})
        elif cmd == 0x80000035:
            if size < 32:
                raise ValueError('truncated fileset command')
            vmaddr, fileoff, nameoff, _ = struct.unpack('<QQII', data[8:32])
            if nameoff < 32 or nameoff >= size or b'\0' not in data[nameoff:]:
                raise ValueError('invalid fileset entry name')
            entries.append({'id': zstring(data[nameoff:]), 'vmaddr': vmaddr, 'fileoff': fileoff})
        position += size
    if position != end or len(uuids) > 1 or len(symtabs) > 1:
        raise ValueError('unconsumed commands or ambiguous UUID/symtab')
    return {'offset': offset, 'filetype': kind, 'flags': flags,
        'load_commands': commands, 'segments': segments, 'sections': sections,
        'entries': entries, 'uuid': uuids[0] if uuids else None,
        'symtab': symtabs[0] if symtabs else None}


DATA_NAME_PREFIXES = ('__ZTV', '__ZTI', '__ZTS', '__ZTT')
DATA_NAME_SUFFIXES = ('metaClassE', 'MetaClassE')


def expects_data(name):
    """Kernel kext data symbols are not only metaClass: vtables, typeinfo and C globals live in data too.

    Used as a parser self-check hint, never as an ABI claim. A mismatch is recorded, not fatal, because
    C++ static data members can end with E without being metaClass.
    """
    return name.endswith(DATA_NAME_SUFFIXES) or name.startswith(DATA_NAME_PREFIXES) or name.startswith('_g')


def observe_symbols(raw, member, names):
    table = member['symtab']
    if not table or not table['nsyms']:
        return {'status': 'KC_BINARY_SYMBOL_NOT_OBSERVABLE', 'reason': 'NO_MEMBER_SYMBOL_TABLE', 'records': []}
    if table['nsyms'] > 10_000_000:
        raise ValueError('unreasonable symbol count')
    # KC member linkedit offsets are collection file offsets. Do not try a
    # member-relative fallback that could manufacture plausible symbol hits.
    for offset, size in [(table['symoff'], table['nsyms']*16), (table['stroff'], table['strsize'])]:
        bounded(raw, offset, size)
        if not any(s['name'] == '__LINKEDIT' and s['fileoff'] <= offset and
                   offset+size <= s['fileoff']+s['filesize'] for s in member['segments']):
            raise ValueError('symtab/string range outside member __LINKEDIT')
    strings = bounded(raw, table['stroff'], table['strsize'])
    records = []
    for i in range(table['nsyms']):
        position = table['symoff']+i*16
        index, ntype, section, desc, value = struct.unpack('<IBBHQ', bounded(raw, position, 16))
        if index >= len(strings):
            raise ValueError('symbol name outside string table')
        end = strings.find(b'\0', index)
        if end < 0:
            raise ValueError('unterminated symbol name')
        name = strings[index:end].decode('utf-8', errors='strict')
        if name not in names:
            continue
        row = {'macho_symbol': name, 'nlist_offset': position, 'n_type': ntype,
            'n_sect': section, 'n_desc': desc, 'value': value,
            'status': 'NOT_A_PUBLIC_SECTION_DEFINITION'}
        if not (ntype & 0xe0) and ntype & 0x0e == 0x0e and ntype & 1 and not ntype & 0x10:
            if not 1 <= section <= len(member['sections']):
                raise ValueError('definition section ordinal outside member')
            sec = member['sections'][section-1]
            if not sec['address'] <= value < sec['address']+sec['size']:
                raise ValueError('symbol value outside claimed section')
            code = bool(sec['flags'] & 0x80000400)
            expected_code = not expects_data(name)
            row.update(section=sec, observed_kind='FUNCTION_SECTION' if code else 'DATA_SECTION',
                expected_kind='FUNCTION' if expected_code else 'DATA',
                kind_matches_role=code == expected_code,
                status='KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI')
            # A kind mismatch is recorded, not raised: the name heuristic is a self-check hint and vtables and
            # C globals are data. The provider claim is "section definition observed", which this still holds.
            if sec['flags'] & 0xff not in (1, 0xc, 0x12):
                filepos = sec['offset']+value-sec['address']
                bounded(raw, filepos, 1)
                if not any(s['fileoff'] <= filepos < s['fileoff']+s['filesize'] and
                           s['vmaddr']+filepos-s['fileoff'] == value for s in member['segments']):
                    raise ValueError('definition section/file/VM mapping mismatch')
                row['definition_file_offset'] = filepos
        records.append(row)
    # A kernel collection member can legitimately carry the same symbol name more than once
    # (local and external entries, or the same definition listed twice). Deduplicate identical
    # (name, value) rows, keep genuinely conflicting ones and mark them, and never invent a winner.
    unique, seen, duplicates, ambiguous = [], {}, [], []
    for row in records:
        key = (row['macho_symbol'], row['value'])
        if key in seen:
            duplicates.append(row['macho_symbol'])
            continue
        seen[key] = row
        unique.append(row)
    by_name = {}
    for row in unique:
        by_name.setdefault(row['macho_symbol'], set()).add(row['value'])
    ambiguous = sorted(name for name, values in by_name.items() if len(values) > 1)
    records = unique
    return {'status': 'MEMBER_SYMBOL_TABLE_PARSED', 'records': records,
            'duplicates_removed': sorted(set(duplicates)), 'ambiguous_values': ambiguous,
        'unobserved': sorted(set(names)-{r['macho_symbol'] for r in records
            if r['status'] == 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI'})}


def observe_collection(path):
    row = {'path': str(path), 'observation': 'NOT_PRESENT', 'members': []}
    if not path.is_file():
        return row
    try:
        with path.open('rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
            before = hashlib.sha256(raw).hexdigest()
            outer = header(raw)
            row.update(sha256=before, bytes=len(raw), outer=outer)
            if outer['filetype'] != 12:
                raise ValueError('expected MH_FILESET collection')
            for bundle, names in TARGETS.items():
                entries = [e for e in outer['entries'] if e['id'] == bundle]
                if len(entries) > 1:
                    raise ValueError('duplicate target member')
                if not entries:
                    continue
                entry = entries[0]
                parsed = header(raw, entry['fileoff'])
                row['members'].append({'bundle_id': bundle, 'entry': entry,
                    'header': parsed, 'symbols': observe_symbols(raw, parsed, names)})
            if hashlib.sha256(raw).hexdigest() != before:
                raise ValueError('KC bytes changed during observation')
            row['observation'] = 'FILESET_PARSED'
    except (OSError, ValueError, UnicodeError, struct.error) as error:
        row.update(observation='KC_OBSERVATION_FAILED', error=str(error), members=[])
    return row


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', required=True, type=Path)
    args = p.parse_args()
    if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        raise ValueError('Intel Darwin required')
    args.out.mkdir(parents=True, exist_ok=False)
    paths = [Path('/System/Library/KernelCollections')/name for name in
             ['BootKernelExtensions.kc', 'SystemKernelExtensions.kc']]
    observations = [observe_collection(path) for path in paths]
    queries = []
    # kmutil prioritises fileset output when these display flags are combined.
    # Query separately; supplied flags alone are not proof of emitted evidence.
    for flag in ['--show-fileset-entries', '--show-kext-uuids', '--show-kext-load-addresses']:
        argv = ['/usr/bin/kmutil', 'inspect', '-a', 'x86_64', '-B', str(paths[0]), '-S', str(paths[1]), flag]
        rc, stdout, stderr = command(argv)
        row = {'argv': argv, 'exit': rc, 'stdout': stdout.decode('utf-8'), 'stderr': stderr.decode('utf-8')}
        filename = 'kmutil-'+flag.removeprefix('--show-')+'.json'
        write(args.out/filename, row)
        queries.append({'flag': flag, 'exit': rc, 'file': filename,
                        'stdout_sha256': hashlib.sha256(stdout).hexdigest()})
    failed = (any(q['exit'] != 0 for q in queries) or not any(r['observation'] == 'FILESET_PARSED' for r in observations) or
              any(r['observation'] == 'KC_OBSERVATION_FAILED' for r in observations))
    target_records = []
    for bundle, names in TARGETS.items():
        for name in names:
            found = [{'collection_path': r['path'], 'collection_sha256': r['sha256'],
                'member_uuid': member['header']['uuid'], 'definition': symbol}
                for r in observations if r['observation'] == 'FILESET_PARSED'
                for member in r['members'] if member['bundle_id'] == bundle
                for symbol in member['symbols']['records'] if symbol['macho_symbol'] == name and
                symbol['status'] == 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI']
            target_records.append({'bundle_id': bundle, 'macho_symbol': name, 'observations': found,
                'status': 'KC_EXTERNAL_SECTION_DEFINITION_OBSERVED_NOT_EXPORT_OR_ABI' if found else
                    'KC_BINARY_SYMBOL_NOT_OBSERVABLE'})
    report = {'schema': 'honor.g1.kc8.v1', 'source_commit': os.environ.get('GITHUB_SHA'),
        'source_run_id': os.environ.get('GITHUB_RUN_ID'), 'collections': observations, 'kmutil_queries': queries,
        'status': 'OBSERVATION_FAILED' if failed else 'COLLECTION_OBSERVED_NOT_EXPORT_OR_ABI_ACCEPTANCE',
        'target_symbols': TARGETS, 'records': target_records, 'scope': 'RUNNER_NOT_USER_TARGET_SYSTEM',
        'target_export': 'NOT_VERIFIED', 'full_abi': 'NOT_VERIFIED', 'kext_load': 'NO-GO', 'gpu_execution': False}
    write(args.out/'kc8-report.json', report)
    print(json.dumps({'status': report['status'], 'collections': [r['observation'] for r in observations]}))
    return 2 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
