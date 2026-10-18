#!/usr/bin/env python3
"""Lexical function-definition candidates; never infer missing/closed source."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from g1_dependency_audit import balanced, mask, no_directives, OGKM_PIN

IDENT = re.compile(r'\b([A-Za-z_]\w*)\s*\(')
FORBIDDEN = {'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'sizeof',
             'alignof', '__alignof__', 'typeof', '__typeof__', 'typedef', 'do'}
EXTS = {'.c', '.h', '.cpp', '.cc', '.hpp'}


def function_candidates(text, names):
    clean = no_directives(mask(text))
    hits, skip_until = [], 0
    for match in IDENT.finditer(clean):
        if match.start() < skip_until:
            continue
        start = max(clean.rfind(c, 0, match.start()) for c in ';{}') + 1
        prefix = clean[start:match.start()].strip()
        if not prefix or not re.fullmatch(r'[A-Za-z_][\w\s*]*', prefix):
            continue
        if set(prefix.split()) & FORBIDDEN:
            continue
        opening = clean.index('(', match.start())
        try:
            end = balanced(clean, opening)
            brace = end + 1
            while brace < len(clean) and clean[brace].isspace():
                brace += 1
            if brace == len(clean) or clean[brace] != '{':
                continue
            tail = balanced(clean, brace, '{', '}')
        except ValueError:
            continue
        skip_until = tail + 1
        if match.group(1) in names:
            hits.append({'name': match.group(1), 'line': text.count('\n', 0, match.start()) + 1,
                         'end_line': text.count('\n', 0, tail) + 1,
                         'storage': 'static' if 'static' in prefix.split() else 'external-candidate',
                         'kind': 'lexical-function-definition-candidate'})
    return hits


def build_index(tree, names):
    found, occurrences, manifest = {}, {}, []
    for path in sorted(tree.rglob('*'), key=lambda p: p.relative_to(tree).as_posix()):
        if not path.is_file() or path.suffix not in EXTS or '.git' in path.parts:
            continue
        raw = path.read_bytes()
        text = raw.decode('utf-8', errors='replace')
        rel = path.relative_to(tree).as_posix()
        manifest.append({'path': rel, 'sha256': hashlib.sha256(raw).hexdigest()})
        for hit in function_candidates(text, names):
            found.setdefault(hit['name'], []).append(dict(hit, path=rel))
        clean = mask(text)
        for match in re.finditer(r'\b[A-Za-z_]\w*\b', clean):
            if match.group() in names:
                occurrences.setdefault(match.group(), []).append({
                    'path': rel, 'line': text.count('\n', 0, match.start()) + 1})
    unknown = sorted(names - set(found))
    return {'schema': 'honor.g1.definition-candidates.v2',
            'level': 'SOURCE-LEXICAL-NOT-PREPROCESSED-NOT-OBJECT-PROVIDERS',
            'limitations': ['Inactive branches and header definitions are retained.',
                           'Data/macro/unsupported definitions remain UNKNOWN, never closed-source.',
                           'Only actual object symbols establish compiled providers.'],
            'source_manifest': manifest, 'definitions': dict(sorted(found.items())),
            'symbols': {name: [f"{h['path']}:{h['line']}" for h in hits]
                        for name, hits in sorted(found.items())},
            'occurrences': dict(sorted(occurrences.items())),
            'missing': unknown, 'unresolved_status': 'UNKNOWN',
            'defining_files': sorted({h['path'] for hits in found.values() for h in hits
                                     if h['path'].endswith('.c') and h['storage'] == 'external-candidate'})}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('tree', type=Path)
    parser.add_argument('names_file', type=Path)
    parser.add_argument('--json', type=Path)
    parser.add_argument('--summary', type=Path, help='small checked-in build input; full hits remain in --json')
    args = parser.parse_args()
    tree = args.tree.resolve()
    pin = subprocess.check_output(['git', '-C', str(tree), 'rev-parse', 'HEAD'], text=True).strip()
    dirty = subprocess.check_output(['git', '-C', str(tree), 'status', '--porcelain',
                                     '--untracked-files=no'], text=True).strip()
    if pin != OGKM_PIN or dirty:
        raise SystemExit('fixed clean OGKM input required')
    names = {s.strip() for s in args.names_file.read_text(encoding='utf-8').splitlines() if s.strip()}
    if not names or any(not re.fullmatch(r'[A-Za-z_]\w*', s) for s in names):
        raise SystemExit('nonempty C identifier list required')
    report = build_index(tree, names)
    report['ogkm_pin'] = pin
    report['requested_symbols'] = sorted(names)
    if args.json:
        args.json.write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    if args.summary:
        summary = {key: report[key] for key in ['schema', 'ogkm_pin', 'level', 'limitations',
                   'requested_symbols', 'symbols', 'missing', 'unresolved_status', 'defining_files']}
        summary['full_evidence'] = {'command': 'tools/index-definitions.py <fixed-ogkm> research/gpu-safety-r5/rm-gap-symbols.txt --json <diagnostics>/rm-gap-index-full.json',
                                    'source_files': len(report['source_manifest']),
                                    'sha256': hashlib.sha256(json.dumps(report, sort_keys=True).encode()).hexdigest()}
        args.summary.write_text(json.dumps(summary, indent=1) + '\n', encoding='utf-8')
    print(json.dumps({'requested': len(names), 'lexical_candidates': len(report['symbols']),
                      'unknown': len(report['missing']), 'defining_c_files': len(report['defining_files']),
                      'closed_source_inferences': 'NOT_PERFORMED'}))


if __name__ == '__main__':
    main()

