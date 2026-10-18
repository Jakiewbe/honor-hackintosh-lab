#!/usr/bin/env python3
"""Explicit nine-symbol source evidence, never a compiled-provider claim.

Complete raw token hits and hashes are retained over the declared tracked C/C++/
header/Makefile/.mk scope. Only reviewed exact patterns nominate sources. Macros,
data and build generators are different evidence kinds, not function UNKNOWNs.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from g1_dependency_audit import OGKM_PIN, mask
from g1_symbol_identity import identity, parse_nm_undefined

REVIEWED = {
    'PEX_DSM_GUID': ('src/nvidia/src/kernel/platform/guids.c',
                     r'^GUID_CONST\s*\(PEX_DSM_GUID\s*,[\s\S]*?\);', 'macro-data-definition-candidate'),
    'g_pSys': ('src/nvidia/src/kernel/core/system.c',
               r'^OBJSYS\s*\*g_pSys\s*=\s*NULL\s*;', 'initialized-data-definition-candidate'),
    'g_resServ': ('src/nvidia/src/kernel/rmapi/rmapi.c',
                  r'^RsServer\s+g_resServ\s*;', 'tentative-data-definition-candidate'),
    'nvEvoGlobal': ('src/nvidia-modeset/src/nvkms-evo.c',
                    r'^NVEvoGlobal\s+nvEvoGlobal\s*=\s*\{', 'initialized-data-definition-candidate'),
    '__nvoc_class_def_Memory': ('src/nvidia/generated/g_mem_nvoc.c',
                               r'^const struct NVOC_CLASS_DEF __nvoc_class_def_Memory\s*=', 'initialized-data-definition-candidate'),
    '__nvoc_class_def_RmResource': ('src/nvidia/generated/g_resource_nvoc.c',
                                   r'^const struct NVOC_CLASS_DEF __nvoc_class_def_RmResource\s*=', 'initialized-data-definition-candidate'),
    '__nvoc_dynamicCast': ('src/nvidia/src/libraries/nvoc/src/runtime.c',
                           r'^Dynamic\s*\*__nvoc_dynamicCast\([^;{}]*\)\s*\{', 'function-definition-candidate'),
    '__nvoc_rtti_provider': ('src/nvidia/src/libraries/nvoc/src/runtime.c',
                             r'^const struct NVOC_RTTI_PROVIDER __nvoc_rtti_provider\s*=\s*\{\s*0\s*\}\s*;', 'initialized-data-definition-candidate'),
    'pNV_KMS_ID': ('src/nvidia-modeset/Makefile',
                   r'\$\(eval \$\(call GENERATE_NVIDSTRING,\s*\\\s*NV_KMS_ID,\s*\\\s*UNIX Open Kernel Mode Setting Driver, \$\(OBJS\)\)\)', 'generated-data-recipe-only'),
}
SUPPORT = {
    'guid_macro': ('src/nvidia/src/kernel/platform/guids.c',
                   r'^#define GUID_CONST\([^\n]*\n[\s\S]*?= \{[^\n]+\}'),
    'id_generator': ('utils.mk', r'^define GENERATE_NVIDSTRING\n[\s\S]*?^endef'),
}
EXTS = {'.c', '.h', '.cc', '.cpp', '.hpp', '.mk'}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def anchor(path, text, pattern, kind):
    matches = list(re.finditer(pattern, text, re.M))
    if len(matches) != 1:
        raise ValueError(f'expected one reviewed anchor in {path}, found {len(matches)}')
    match = matches[0]
    # C candidate anchors must not originate in a comment/string.
    if path.endswith('.c') and not mask(text)[match.start():match.end()].strip():
        raise ValueError('reviewed anchor is only comment/string text')
    return {'path': path, 'kind': kind, 'line': text.count('\n', 0, match.start()) + 1,
            'end_line': text.count('\n', 0, match.end()) + 1,
            'excerpt': match.group(), 'source_sha256': sha(text.encode('utf-8'))}


def inventory(tree, nm_text):
    names = parse_nm_undefined(nm_text)
    if len(names) != len(set(names)) or {identity(s)['source_spelling'] for s in names} != set(REVIEWED):
        raise ValueError('expected exactly the nine reviewed raw symbols')
    tracked = subprocess.check_output(['git', '-C', str(tree), 'ls-files', '-z']).decode('utf-8').split('\0')
    files, contents, occurrences = [], {}, {name: [] for name in REVIEWED}
    for rel in sorted(p for p in tracked if p and (Path(p).suffix in EXTS or Path(p).name == 'Makefile')):
        raw = (tree/rel).read_bytes()
        text = raw.decode('utf-8')
        files.append({'path': rel, 'sha256': sha(raw)})
        contents[rel] = text
        for match in re.finditer(r'\b[A-Za-z_]\w*\b', text):
            if match.group() in occurrences:
                occurrences[match.group()].append({'path': rel, 'line': text.count('\n', 0, match.start())+1})
    records = []
    for symbol in names:
        row = identity(symbol)
        path, pattern, kind = REVIEWED[row['source_spelling']]
        row.update({'source_candidate': anchor(path, contents[path], pattern, kind),
                    'object_provider': 'NOT_OBSERVED',
                    'raw_text_occurrences': occurrences[row['source_spelling']]})
        records.append(row)
    support = {key: anchor(path, contents[path], pattern, 'reviewed-macro-or-generator')
               for key, (path, pattern) in SUPPORT.items()}
    return {'schema': 'honor.g1.special-symbol-sources.v1', 'ogkm_pin': OGKM_PIN,
            'level': 'SOURCE_CANDIDATES_AND_GENERATION_RECIPE_ONLY',
            'scope': 'all tracked .c/.h/.cc/.cpp/.hpp/.mk and Makefile files',
            'input_nm_sha256': sha(nm_text.encode('utf-8')),
            'source_manifest': files, 'records': records, 'support': support,
            'limitations': ['Raw token hits include comments and inactive code; none alone establish definitions.',
                           'Exact anchors nominate reviewed source candidates; preprocessor and actual object symbols are still required.',
                           'pNV_KMS_ID has a public generation recipe, but no generated Darwin object is established.',
                           'This nine-symbol set is not the full undefined inventory or closure.']}


def summary(report):
    encoded = json.dumps(report, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode('utf-8')
    return {k: v for k, v in report.items() if k not in ('records', 'source_manifest')} | {
        'records': [{k: v for k, v in row.items() if k != 'raw_text_occurrences'} for row in report['records']],
        'scanned_files': len(report['source_manifest']), 'full_canonical_sha256': sha(encoded)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--nv', type=Path, required=True)
    parser.add_argument('--nm', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--summary', type=Path, required=True)
    args = parser.parse_args()
    pin = subprocess.check_output(['git', '-C', str(args.nv), 'rev-parse', 'HEAD'], text=True).strip()
    dirty = subprocess.check_output(['git', '-C', str(args.nv), 'status', '--porcelain', '--untracked-files=no'], text=True).strip()
    if pin != OGKM_PIN or dirty:
        raise SystemExit('fixed clean OGKM required')
    report = inventory(args.nv, args.nm.read_bytes().decode('utf-8'))
    for path, data in [(args.out, report), (args.summary, summary(report))]:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, ensure_ascii=True, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(f'source candidates: {len(report["records"])}; actual object providers: NOT_OBSERVED')


if __name__ == '__main__':
    main()
