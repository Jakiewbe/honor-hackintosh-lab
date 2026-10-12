#!/usr/bin/env python3
"""Offline C0 evidence validation. No compiler, network, hardware or driver use.

Structure mode validates the recorded source slice, including honest BLOCKED
entries. Closure mode refuses every unresolved dependency. Neither is ABI or
runtime validation. C lexical regions are unpreprocessed, not a full callgraph.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path, PurePosixPath
import re

PINS = {
    'drm-kmod': 'dba60e1e9465d4d6b2d4e7916174f7b915c35fb4',
    'linux': '830b3c68c1fb1e9176028d02ef86f3cf76aa2476',
    'freebsd-src': '8c9ce319fef765890ce518cab85d3a470b669849',
    'xnu': 'a1e26a70f38d1d7daa7b49b258e2f8538ad81650',
    'IOGraphics': '4d3fd008c80d1414c9da8f02ea67d534b47158c2',
}
REPOS = {'drm-kmod': 'freebsd/drm-kmod', 'linux': 'torvalds/linux',
         'freebsd-src': 'freebsd/freebsd-src', 'xnu': 'apple-oss-distributions/xnu',
         'IOGraphics': 'apple-oss-distributions/IOGraphics'}


def blob_id(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def c_mask(text):
    """Preserve offsets/newlines, mask comments and quoted literals."""
    return re.sub(r'/\*[\s\S]*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                  lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), text)


def function_region(text, symbol):
    masked = c_mask(text)
    found = []
    for m in re.finditer(r'\b' + re.escape(symbol) + r'\s*\(', masked):
        pos = masked.index('(', m.start()); depth = 1; end = pos + 1
        while end < len(masked) and depth:
            depth += (masked[end] == '(') - (masked[end] == ')'); end += 1
        rest = re.match(r'\s*\{', masked[end:])
        if not rest:
            continue
        start = end + rest.end() - 1; depth = 1; end = start + 1
        while end < len(masked) and depth:
            depth += (masked[end] == '{') - (masked[end] == '}'); end += 1
        if depth:
            raise ValueError('Unbalanced function: ' + symbol)
        found.append((text.count('\n', 0, m.start()) + 1, masked[start:end]))
    if len(found) != 1:
        raise ValueError('Expected one lexical definition: ' + symbol + ' found=' + str(len(found)))
    return found[0]


def safe_path(root, value):
    path = PurePosixPath(value)
    if path.is_absolute() or '..' in path.parts or '\\' in value or ':' in value:
        raise ValueError('Unsafe relative path: ' + value)
    result = (root / value).resolve()
    if not result.is_relative_to(root.resolve()):
        raise ValueError('Path escaped root: ' + value)
    return result


def read_csv(path):
    with path.open(encoding='utf-8', newline='') as f:
        return list(csv.DictReader(f))


def inspect(baseline, cache):
    lock = json.loads((baseline / 'source-lock.json').read_text(encoding='utf-8'))
    if lock['schema_version'] != 1 or lock['runtime_decision'] != 'RUNTIME_NO_GO':
        raise ValueError('Invalid schema/runtime claim')
    if {x['id']: x['commit'] for x in lock['components']} != PINS:
        raise ValueError('Component commit mismatch')
    if len(lock['components']) != len(PINS) or {x['id']: x['repo'] for x in lock['components']} != REPOS:
        raise ValueError('Component repository mismatch/duplicate')
    if lock['scope'] != 'REVIEWED_SOURCE_SLICE_NOT_DEPENDENCY_CLOSURE':
        raise ValueError('Unsupported closure claim')
    sources, source_objects = {}, {}
    for row in lock['files']:
        key = (row['component'], row['path'])
        if key in sources or row['commit'] != PINS[row['component']]:
            raise ValueError('Duplicate source or wrong version: ' + str(key))
        if row['repo'] != REPOS[row['component']]:
            raise ValueError('Source repository mismatch')
        if row['patches'] or row['status'] != 'OBSERVED':
            raise ValueError('Unreviewed patch or observation status')
        if row['path'].endswith('.c'):
            target = row['object_target']
            if not target or row['object_status'] != 'NOT_COMPILED' or target in source_objects:
                raise ValueError('Missing/duplicate/unproven source-object mapping')
            source_objects[target] = key
        if not re.fullmatch(r'[0-9a-f]{40}', row['blob_sha']):
            raise ValueError('Missing Git blob: ' + str(key))
        data = safe_path(cache / row['component'], row['path']).read_bytes()
        if blob_id(data) != row['blob_sha'] or hashlib.sha256(data).hexdigest() != row['sha256']:
            raise ValueError('Source hash mismatch: ' + str(key))
        sources[key] = data.decode('utf-8')
    licenses = read_csv(baseline / 'license-manifest.csv')
    seen = set()
    for row in licenses:
        key = (row['component'], row['path'])
        if key in seen or key not in sources:
            raise ValueError('Duplicate/unknown license row: ' + str(key))
        seen.add(key)
        if row['blob_sha'] != next(x['blob_sha'] for x in lock['files'] if (x['component'],x['path']) == key):
            raise ValueError('License source mismatch')
        if row['status'] not in {'HEADER_OBSERVED', 'BLOCKED'} or not row['redistribution']:
            raise ValueError('Invalid license status')
        if row['status'] == 'HEADER_OBSERVED':
            if not row['evidence'] or row['evidence'] not in sources[key]:
                raise ValueError('Missing license evidence: ' + str(key))
        elif row['evidence'] or row['license'] != 'UNRESOLVED':
            raise ValueError('Contradictory blocked license')
    if seen != set(sources):
        raise ValueError('Missing license inventory rows')
    symbols = read_csv(baseline / 'symbol-inventory.csv')
    objects, definitions = {}, {}
    for row in symbols:
        key = (row['component'], row['path'])
        if key not in sources or row['id'] in definitions:
            raise ValueError('Unknown source or duplicate symbol id')
        source_row = next(x for x in lock['files'] if (x['component'], x['path']) == key)
        if row['commit'] != PINS[row['component']] or row['blob_sha'] != source_row['blob_sha'] or not row['context'] or not row['object_target']:
            raise ValueError('Missing version/context/object')
        if row['path'].endswith('.c') and row['object_target'] != source_row['object_target']:
            raise ValueError('Symbol source-object mapping disagrees with lock')
        if row['object_status'] != 'NOT_COMPILED' or row['xnu_status'] != 'BLOCKED':
            raise ValueError('Unproven implementation/build claim')
        target = row['object_target']
        if target in objects and objects[target] != key:
            raise ValueError('Duplicate object mapping: ' + target)
        objects[target] = key
        line, body = function_region(sources[key], row['symbol'])
        if line != int(row['defined_line']):
            raise ValueError('Wrong symbol definition line: ' + row['symbol'])
        definitions[row['id']] = (row, body)
    edges = json.loads((baseline / 'callgraph-edges.json').read_text(encoding='utf-8'))
    edge_ids = set()
    for edge in edges:
        key = (edge['from'], edge['to'], edge['kind'])
        if key in edge_ids:
            raise ValueError('Duplicate edge')
        edge_ids.add(key)
        src, body = definitions[edge['from']]; dst, _ = definitions[edge['to']]
        if edge['kind'] == 'DIRECT_CALL':
            if not re.search(r'\b' + re.escape(dst['symbol']) + r'\s*\(', body):
                raise ValueError('Missing direct call: ' + str(key))
        elif edge['kind'] == 'CALLBACK_ASSIGNMENT':
            if not re.search(edge['assignment_pattern'], body):
                raise ValueError('Missing callback assignment: ' + str(key))
        else:
            raise ValueError('Unknown edge kind')
    apis = json.loads((baseline / 'api-contracts.json').read_text(encoding='utf-8'))
    if not apis or len({x['id'] for x in apis}) != len(apis):
        raise ValueError('Missing/duplicate APIs')
    for api in apis:
        if api['required'] is not True or api['xnu_status'] != 'BLOCKED' or api['success_allowed'] is not False:
            raise ValueError('Required unimplemented API may not report success: ' + api['id'])
        if not api['source_refs'] or not api['contract'] or not api['context']:
            raise ValueError('Missing API contract')
        for ref in api['source_refs']:
            text = sources[(ref['component'], ref['path'])]
            if not ref['token'] or ref['token'] not in c_mask(text):
                raise ValueError('Missing API evidence: ' + api['id'])
    pm = sources[('freebsd-src', 'sys/compat/linuxkpi/common/include/linux/pm_runtime.h')]
    _, pm_body = function_region(pm, 'pm_runtime_get_sync')
    if not re.fullmatch(r'\{\s*return\s+0\s*;\s*\}', pm_body):
        raise ValueError('Pinned base PM no-op evidence changed; re-review before proceeding')
    blockers = list(lock['blockers'])
    blockers += ['LICENSE:' + x['component'] + '/' + x['path'] for x in licenses if x['status'] == 'BLOCKED']
    blockers += ['API:' + x['id'] for x in apis if x['xnu_status'] == 'BLOCKED']
    if not blockers:
        raise ValueError('Source slice cannot claim closed dependency graph')
    return {'structure': 'PASS', 'files': len(sources), 'symbols': len(symbols),
            'edges': len(edges), 'objects_compiled': 0, 'closure': 'BLOCKED',
            'upstream_pm_empty_success_observed': True,
            'blockers': blockers, 'runtime_decision': 'RUNTIME_NO_GO'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, default=Path('research/independent-i915'))
    parser.add_argument('--cache', type=Path, default=Path('.cache'))
    parser.add_argument('--mode', choices=['structure', 'closure'], default='closure')
    args = parser.parse_args()
    try:
        result = inspect(args.baseline, args.cache)
    except (ValueError, KeyError, OSError, TypeError, json.JSONDecodeError) as e:
        print(json.dumps({'structure': 'FAIL', 'error': str(e), 'runtime_decision': 'RUNTIME_NO_GO'}))
        return 1
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if args.mode == 'structure' else 2


if __name__ == '__main__':
    raise SystemExit(main())
