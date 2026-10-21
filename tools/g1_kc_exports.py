#!/usr/bin/env python3
"""Does the shipped kernel collection carry the loader-consumed export metadata for a kext member?

The question this answers: can the 27 local-only IOAccel names be shown to be *externally* exported by
metadata a loader consumes, using only the shipped kernel collection?

It reports, for one fileset member:
  * the load commands that could carry exports (LC_DYLD_INFO, LC_DYLD_INFO_ONLY, LC_DYLD_EXPORTS_TRIE),
  * the section list (so __LINKINFO / __symbolsets presence is visible),
  * and, when an export trie exists, whether each requested name appears in it.

Read-only. It never loads anything and never treats a missing trie as a pass.
"""
import argparse
import json
import mmap
import struct
import sys

import g1_kc8 as kc

EXPORT_TRIE = 0x80000033
DYLD_INFO = (0x22, 0x80000022)


def uleb(raw, position, end):
    result = shift = 0
    while position < end:
        byte = raw[position]
        position += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, position
        shift += 7
        if shift > 63:
            break
    raise ValueError('ULEB128 overflow')


def export_trie(raw, offset, size):
    """Yield the exported names of a dyld export trie."""
    end = offset + size
    if size <= 0 or end > len(raw):
        raise ValueError('export trie outside file')
    stack = [(0, b'')]
    seen = set()
    while stack:
        position, prefix = stack.pop()
        if position in seen:
            continue
        seen.add(position)
        terminal_size, cursor = uleb(raw, offset + position, end)
        if terminal_size:
            cursor += terminal_size
        if cursor >= end:
            continue
        child_count = raw[cursor]
        cursor += 1
        for _ in range(child_count):
            edge, cursor = uleb(raw, cursor, end)
            node, cursor = uleb(raw, cursor, end)
            edge_text = raw[cursor:cursor + edge].decode('utf-8', 'replace')
            cursor += edge
            stack.append((node, prefix + edge_text.encode('utf-8', 'replace')))
        if prefix:
            yield prefix.decode('utf-8', 'replace')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('collection')
    parser.add_argument('bundle')
    parser.add_argument('--names', help='JSON file with a list of symbol names to look up')
    parser.add_argument('--controls', default='', help='comma-separated names that must be ABSENT')
    parser.add_argument('--require', default='', help='comma-separated names that must be PRESENT')
    args = parser.parse_args()

    with open(args.collection, 'rb') as file, mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ) as raw:
        outer = kc.header(raw)
        if outer['filetype'] != 12:
            raise SystemExit('not a MH_FILESET collection')
        entries = [e for e in outer['entries'] if e['id'] == args.bundle]
        if len(entries) != 1:
            raise SystemExit('expected one fileset entry for %s' % args.bundle)
        member = kc.header(raw, entries[0]['fileoff'])
        command_ids = sorted({int(c['cmd'], 16) for c in member['load_commands']})
        export_commands = []
        for command in member['load_commands']:
            kind = int(command['cmd'], 16)
            if kind == EXPORT_TRIE:
                data = raw[command['offset']:command['offset'] + command['bytes']]
                off, size = struct.unpack_from('<II', data, 8)
                export_commands.append(dict(command='LC_DYLD_EXPORTS_TRIE', fileoff=off, size=size))
            elif kind in DYLD_INFO:
                data = raw[command['offset']:command['offset'] + command['bytes']]
                export_off, export_size = struct.unpack_from('<II', data, 40)
                export_commands.append(dict(command='LC_DYLD_INFO(_ONLY)', fileoff=export_off,
                                            size=export_size))
        sections = [dict(name=s['name'], segment=s['segment'], size=s['size'])
                    for s in member['sections'] if s['name'] in ('__symbolsets', '__info_plist',
                                                                 '__kmod', '__constants')]
        report = dict(collection=args.collection, bundle=args.bundle,
                      member_fileoff=entries[0]['fileoff'],
                      load_command_ids=['0x%x' % c for c in command_ids],
                      export_commands=export_commands,
                      linkinfo_sections=sections,
                      trie_present=False, trie_names=0,
                      requested={}, controls={}, required={})
        names = []
        if args.names:
            names = json.loads(open(args.names, encoding='utf-8').read())
        found = set()
        if export_commands:
            for entry in export_commands:
                if not entry['size']:
                    continue
                try:
                    found |= set(export_trie(raw, entry['fileoff'], entry['size']))
                except Exception as error:
                    entry['error'] = str(error)[:120]
            report['trie_present'] = bool(found)
            report['trie_names'] = len(found)
        for name in names:
            report['requested'][name] = name in found
        for name in filter(None, (s.strip() for s in args.controls.split(','))):
            report['controls'][name] = name in found
        for name in filter(None, (s.strip() for s in args.require.split(','))):
            report['required'][name] = name in found
        report['requested_exported'] = sum(1 for v in report['requested'].values() if v)
        report['verdict'] = (
            'EXPORT_TRIE_ABSENT_NOT_OBSERVABLE' if not report['trie_present'] else
            'EXPORT_TRIE_PRESENT')
        print(json.dumps(report, indent=1))


if __name__ == '__main__':
    sys.exit(main())
