#!/usr/bin/env python3
"""Offline source-evidence gate. No make/compiler/driver code is executed.

Structure success means consistent BLOCKED contracts, never GPU success.
Lexical C checks do not evaluate preprocessor branches or establish ABI.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re

from r14c0_validate_dependency_baseline import PINS, REPOS, blob_id, safe_path, function_region, c_mask

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'research/independent-i915/c01'
GENERATED = {
    'bus_if.h': ('sys/kern/bus_if.m', 'sys/tools/makeobjops.awk'),
    'device_if.h': ('sys/kern/device_if.m', 'sys/tools/makeobjops.awk'),
    'pci_if.h': ('sys/dev/pci/pci_if.m', 'sys/tools/makeobjops.awk'),
    'pci_iov_if.h': ('sys/dev/pci/pci_iov_if.m', 'sys/tools/makeobjops.awk'),
    'acpi_if.h': ('sys/dev/acpica/acpi_if.m', 'sys/tools/makeobjops.awk'),
    'fb_if.h': ('sys/dev/fb/fb_if.m', 'sys/tools/makeobjops.awk'),
    'vnode_if.h+vnode_if_newproto.h+vnode_if_typedef.h': ('sys/kern/vnode_if.src', 'sys/tools/vnode_if.awk'),
}
ORDER = ['drm-kmod/linuxkpi/gplv2/include', 'drm-kmod/linuxkpi/bsd/include',
         'freebsd-src/sys/compat/linuxkpi/common/include',
         'freebsd-src/sys/compat/linuxkpi/dummy/include', 'drm-kmod/include',
         'drm-kmod/include/drm', 'drm-kmod/include/uapi']


def read_json(base, name):
    return json.loads((base / name).read_text(encoding='utf-8'))


def read_csv(base, name):
    with (base / name).open(encoding='utf-8', newline='') as f:
        return list(csv.DictReader(f))


def validate(base=BASE, cache=ROOT / '.cache'):
    lock = read_json(base, 'source-lock.json')
    if lock['scope'] != 'SOURCE_STATIC_ONLY' or lock['runtime'] != 'RUNTIME_NO_GO':
        raise ValueError('Unsupported runtime/closure claim')
    if len(lock['components']) != len(PINS) or {x['id']: x['commit'] for x in lock['components']} != PINS:
        raise ValueError('Wrong component pins')
    sources = {}
    rows = {}
    for row in lock['files']:
        key = row['component'], row['path']
        if key in rows or row['commit'] != PINS[key[0]] or row['repo'] != REPOS[key[0]]:
            raise ValueError('Duplicate/wrong source pin')
        data = safe_path(cache / key[0], key[1]).read_bytes()
        if blob_id(data) != row['blob_sha'] or hashlib.sha256(data).hexdigest() != row['sha256']:
            raise ValueError('Source bytes mismatch: ' + str(key))
        if row['tree_verified'] is not (key[0] != 'xnu'):
            raise ValueError('Unproven tree attestation')
        rows[key] = row
        sources[key] = data.decode('utf-8')
    licenses = read_csv(base, 'license-manifest.csv')
    if len(licenses) != len(rows) or {(x['component'], x['path']) for x in licenses} != set(rows):
        raise ValueError('License coverage incomplete')
    for row in licenses:
        key = row['component'], row['path']
        if row['blob_sha'] != rows[key]['blob_sha']:
            raise ValueError('License source mismatch')
        if row['status'] == 'HEADER_OBSERVED_NOT_LEGAL_CLOSURE':
            line = int(row['evidence_line'])
            if line <= 0 or sources[key].splitlines()[line - 1].strip() != row['evidence']:
                raise ValueError('Invented license evidence')
            if not re.search(r'SPDX-License-Identifier:|Redistribution and use|Permission is hereby granted|Apple Public Source License|APPLE PUBLIC SOURCE LICENSE|Public domain\.', row['evidence']):
                raise ValueError('Line is not a license notice')
        elif row['status'] != 'BLOCKED_NO_FILE_HEADER' or row['evidence'] or row['evidence_line']:
            raise ValueError('Unsupported license claim')
    bodies = {}
    for row in read_csv(base, 'provider-inventory.csv'):
        key = row['component'], row['path']
        line, body = function_region(sources[key], row['symbol'])
        identity = key + (row['symbol'],)
        if identity in bodies or line != int(row['line']) or row['blob_sha'] != rows[key]['blob_sha']:
            raise ValueError('Invalid provider identity')
        if row['status'] != 'LEXICAL_DEFINITION_NOT_ABI' or hashlib.sha256(body.encode()).hexdigest() != row['body_sha256']:
            raise ValueError('Provider body or ABI claim mismatch')
        bodies[identity] = body
    def body(symbol):
        matches = [b for k, b in bodies.items() if k[2] == symbol]
        if len(matches) != 1:
            raise ValueError('Missing/ambiguous required provider: ' + symbol)
        return matches[0]
    # Real defect evidence: timeout cannot be returned through the void chain.
    if not re.search(r'ops\s*->\s*enable\s*\([^;]+;\s*power_well->hw_enabled\s*=\s*true', body('intel_power_well_enable')):
        raise ValueError('Power cached-state evidence changed')
    if 'intel_de_wait_for_set' not in body('hsw_wait_for_power_well_enable') or re.search(r'\breturn\s+-', body('hsw_wait_for_power_well_enable')):
        raise ValueError('Missing poll evidence')
    if not re.fullmatch(r'\{\s*return\s+0\s*;\s*\}', body('pm_runtime_get_sync')):
        raise ValueError('PM no-op evidence changed')
    edges = read_json(base, 'edges.json')
    if len(edges) != 14 or len({(e['caller'], e['callee']) for e in edges}) != 14:
        raise ValueError('Missing/duplicate scoped call evidence')
    for edge in edges:
        body(edge['callee'])
        if edge['kind'] != 'LEXICAL_DIRECT_CALL_NOT_PREPROCESSED' or not re.search(r'\b' + re.escape(edge['callee']) + r'\s*\(', body(edge['caller'])):
            raise ValueError('Invented direct call')
    observed = set(rows)
    # Candidates may include the larger immutable C0 slice. This still does
    # not resolve .OBJDIR, machine aliases, branches or preprocessor macros.
    prior = read_json(ROOT / 'research/independent-i915', 'source-lock.json')
    observed.update((r['component'], r['path']) for r in prior['files'])
    expected_includes = []
    for key, text in sources.items():
        if key[0] != 'freebsd-src' or not key[1].endswith(('.h', '.c')):
            continue
        for line, raw in enumerate(text.splitlines(), 1):
            match = re.match(r'\s*#\s*include\s*[<"]([^>"]+)[>"]', raw)
            if match:
                candidates = sorted(c + '/' + p for c, p in observed if p.endswith('/' + match[1]))
                expected_includes.append((key[0], key[1], line, match[1], candidates))
    inc = read_csv(base, 'transitive-includes.csv')
    if len(inc) != len(expected_includes):
        raise ValueError('Missing transitive include ledger')
    actual = set()
    for row in inc:
        candidates = sorted(row['candidates'].split(';')) if row['candidates'] else []
        record = (row['component'], row['path'], int(row['line']), row['include'], tuple(candidates))
        if record in actual:
            raise ValueError('Duplicate include row')
        actual.add(record)
        expected_status = 'OBSERVED_CANDIDATE_NOT_PREPROCESSED' if candidates else 'BLOCKED_NOT_IN_REVIEWED_SLICE'
        if row['status'] != expected_status:
            raise ValueError('Invented preprocessed provider')
    if actual != {(c, p, line, inc, tuple(candidates)) for c, p, line, inc, candidates in expected_includes}:
        raise ValueError('Wrong include provider evidence')
    absence = read_json(base, 'compiler-types-absence.json')
    tree_url = 'https://api.github.com/repos/freebsd/freebsd-src/git/trees/273ae9d77bed762f5fbf3190f5437ab36748df29'
    if absence['url'] != tree_url or absence['commit'] != PINS['freebsd-src'] or absence['observed_present'] is not False:
        raise ValueError('Invalid conditional-header absence evidence')
    if absence['request_url'] != tree_url + '?recursive=1':
        raise ValueError('Wrong tree query scope')
    tree_path = base / 'parent-tree-evidence.json'
    data = tree_path.read_bytes()
    tree = json.loads(data)
    if hashlib.sha256(data).hexdigest() != absence['snapshot_sha256'] or tree['truncated'] is not False or tree['sha'] != absence['tree_sha'] or tree['url'] != tree_url:
        raise ValueError('Incomplete/mismatched parent tree')
    if absence['relative_path'] != 'common/include/linux/compiler_types.h' or any(x['path'] == absence['relative_path'] for x in tree['tree']):
        raise ValueError('Conditional header absence not established')
    b = read_json(base, 'build-contract.json')
    if b['closure'] != 'BLOCKED' or any(b[k] is not False for k in ['make_executed', 'preprocessed', 'objects_built']):
        raise ValueError('Unsupported build claim')
    if b['append_order'] != ORDER or not b['effective_include_order'].startswith('BLOCKED;'):
        raise ValueError('Include order/closure invented')
    if len(b['generated']) != len(GENERATED) or {x['output']: (x['input'], x['generator']) for x in b['generated']} != GENERATED:
        raise ValueError('Missing/wrong generated interface input')
    for rule in b['generated']:
        if rule['status'] != 'NOT_GENERATED':
            raise ValueError('Invented generated result')
        for field in ['input', 'generator']:
            if ('freebsd-src', rule[field]) not in rows:
                raise ValueError('Missing generator/input source')
    contracts = read_json(base, 'power-contracts.json')
    expected = {'PCI_MMIO_OWNER', 'POWER_WELL_TRANSITION', 'PM_ACK_SEMANTICS', 'STOP_AND_DRAIN'}
    if len(contracts) != len(expected) or {x['id'] for x in contracts} != expected:
        raise ValueError('Missing required power contract')
    for c in contracts:
        if c['status'] != 'BLOCKED' or c['implemented'] is not False:
            raise ValueError('Fake implementation claim')
        if any(not isinstance(c[k], str) or not c[k].strip() for k in ['pre', 'post', 'failure', 'missing']):
            raise ValueError('Missing failure/ownership contract')
        for symbol in c['evidence']:
            body(symbol)
    # PM consumer treats negative values as an ack; no errno-based rejection.
    pm = c_mask(sources['xnu', 'iokit/Kernel/IOServicePM.cpp'])
    if not re.search(r'if\s*\(\(result\s*==\s*IOPMAckImplied\)\s*\|\|\s*\(result\s*<\s*0\)\)\s*\{\s*fDriverTimer\s*=\s*0', pm):
        raise ValueError('XNU PM consumer evidence changed')
    return {'structure': 'PASS', 'closure': 'BLOCKED', 'runtime': 'RUNTIME_NO_GO',
            'sources': len(rows), 'provider_definitions': len(bodies), 'contracts': len(contracts),
            'scope': 'LEXICAL_STATIC; NOT PREPROCESSED/COMPILED/HARDWARE'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, default=BASE)
    parser.add_argument('--cache', type=Path, default=ROOT / '.cache')
    parser.add_argument('--mode', choices=['structure', 'closure'], default='closure')
    args = parser.parse_args()
    try:
        result = validate(args.base, args.cache)
    except (ValueError, KeyError, OSError, IndexError, TypeError) as e:
        print(json.dumps({'structure': 'FAIL', 'error': str(e)}, ensure_ascii=False))
        return 1
    print(json.dumps(result))
    return 0 if args.mode == 'structure' else 2


if __name__ == '__main__':
    raise SystemExit(main())
