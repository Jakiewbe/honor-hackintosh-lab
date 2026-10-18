#!/usr/bin/env python3
"""Observe the nine nominated providers from this run's explicit build manifest.

No glob, no compilation and no driver execution. Missing/failed sources remain
visible; this report cannot establish full RM/modeset closure.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
from g1_dependency_audit import OGKM_PIN


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def defined_symbols(text):
    found = set()
    for line in text.splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r'\s*[0-9a-fA-F]+\s+([A-Za-z?])\s+(_[A-Za-z0-9_.$]+)\s*', line)
        if not match or match.group(1).upper() == 'U':
            raise ValueError('unexpected nm -gU record')
        found.add(match.group(2))
    return found


def validate_object(entry, candidate, object_root):
    if entry.get('compile_exit') != 0:
        raise ValueError('compile failed')
    if entry.get('source_sha256') != candidate['source_sha256']:
        raise ValueError('compiled source does not match the reviewed source hash')
    requested = Path(entry['object'])
    obj = requested.resolve()
    if obj.parent != object_root.resolve() or not obj.is_file() or requested.is_symlink():
        raise ValueError('object outside this run or missing')
    raw = obj.read_bytes()
    if digest(raw) != entry.get('object_sha256'):
        raise ValueError('object hash mismatch')
    if (len(raw) < 32 or struct.unpack_from('<II', raw) != (0xfeedfacf, 0x01000007)
            or struct.unpack_from('<I', raw, 12)[0] != 1):
        raise ValueError('expected x86_64 MH_OBJECT')
    return obj


def observe(source_report, native_report, object_root, out, runner):
    if source_report.get('ogkm_pin') != OGKM_PIN or native_report.get('pins', {}).get('nv') != OGKM_PIN:
        raise ValueError('source/native OGKM pin mismatch')
    if not isinstance(native_report.get('build_manifest'), list):
        raise ValueError('current explicit build manifest required')
    results, observed = [], {}
    for record in source_report['records']:
        candidate = record['source_candidate']
        rel = candidate['path']
        row = {k: record[k] for k in ('macho_symbol', 'source_spelling')}
        row.update({'source': rel, 'attempts': [], 'status': 'NOT_BUILT'})
        if candidate['kind'] == 'generated-data-recipe-only':
            row['status'] = 'GENERATION_RECIPE_ONLY_NO_OBJECT_NOMINATED'
        for entry in native_report['build_manifest']:
            if entry.get('source') != rel:
                continue
            item = {'compile_exit': entry.get('compile_exit'), 'role': entry.get('role')}
            row['attempts'].append(item)
            if entry.get('compile_exit') != 0:
                item['status'] = 'COMPILE_FAILED'
                continue
            obj = validate_object(entry, candidate, object_root)
            key = (str(obj), entry['object_sha256'])
            if key not in observed:
                dest = out/(obj.stem+'-defined.txt')
                argv = ['xcrun', 'nm', '-gU', str(obj)]
                rc, stdout, stderr = runner(argv)
                dest.write_text(stdout, encoding='utf-8', newline='\n')
                dest.with_suffix('.stderr.txt').write_text(stderr, encoding='utf-8', newline='\n')
                if rc:
                    raise ValueError(f'nm failed for {obj.name}: {rc}')
                observed[key] = (defined_symbols(stdout), {'command': argv, 'exit': rc,
                                  'file': dest.name, 'sha256': digest(stdout.encode('utf-8'))})
            defined, diagnostic = observed[key]
            item.update({'status': 'EXPORTED' if row['macho_symbol'] in defined else 'NOT_EXPORTED',
                         'object': str(obj), 'object_sha256': entry['object_sha256'], 'nm': diagnostic})
        statuses = {a['status'] for a in row['attempts']}
        if row['attempts']:
            row['status'] = 'OBJECT_PROVIDER_OBSERVED' if 'EXPORTED' in statuses else (
                'COMPILED_WITHOUT_TARGET_EXPORT' if 'NOT_EXPORTED' in statuses else 'COMPILE_FAILED')
        results.append(row)
    return {'schema': 'honor.g1.special-object-providers.v1',
            'level': 'SELECTED_OBJECT_EXPORTS_NOT_CLOSURE_OR_ABI_OR_RUNTIME',
            'records': results, 'closure_status': 'NOT_ESTABLISHED', 'device_execution': False}


def run(argv):
    result = subprocess.run(argv, capture_output=True, text=True, encoding='utf-8', timeout=180)
    return result.returncode, result.stdout, result.stderr


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sources', type=Path, required=True)
    parser.add_argument('--native-report', type=Path, required=True)
    parser.add_argument('--object-root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    # Reject prior diagnostics rather than leaving a stale success on failure.
    args.out.mkdir(parents=True, exist_ok=False)
    report = observe(json.loads(args.sources.read_text(encoding='utf-8')),
                     json.loads(args.native_report.read_text(encoding='utf-8')),
                     args.object_root, args.out, run)
    report.update({'source_report_sha256': digest(args.sources.read_bytes()),
                   'native_report_sha256': digest(args.native_report.read_bytes())})
    (args.out/'report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
    print('selected object exports observed; missing/failed providers remain explicit; closure NOT_ESTABLISHED')


if __name__ == '__main__':
    main()
