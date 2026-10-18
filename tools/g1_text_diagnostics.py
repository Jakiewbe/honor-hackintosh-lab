#!/usr/bin/env python3
"""Prepare an explicit UTF-8 diagnostic publication set; reject disguised binaries."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

ALLOWED = {'.txt', '.json', '.md', '.ll', '.cpp', '.c', '.h', '.d'}
MAGICS = {bytes.fromhex(h) for h in ['cffaedfe', 'feedfacf', 'cefaedfe', 'feedface', 'cafebabe', 'bebafeca']}


def prepare(source, out):
    source, out = source.resolve(), out.resolve()
    if not source.is_dir():
        raise ValueError('diagnostic input directory missing')
    if out == source or source in out.parents or out in source.parents:
        raise ValueError('publication directory must be separate from input')
    out.mkdir(parents=True, exist_ok=False)
    included, excluded = [], []
    for p in sorted(source.rglob('*')):
        if p.is_symlink():
            raise ValueError('symlink in diagnostic input')
        if not p.is_file():
            continue
        rel = p.relative_to(source)
        if any(part.endswith('.dSYM') for part in rel.parts) or p.suffix not in ALLOWED:
            excluded.append(rel.as_posix())
            continue
        data = p.read_bytes()
        if data[:4] in MAGICS or b'\0' in data:
            raise ValueError('binary content in text diagnostic: ' + rel.as_posix())
        data.decode('utf-8', errors='strict')
        dest = out/rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(p, dest)
        included.append({'path': rel.as_posix(), 'bytes': len(data),
                         'sha256': hashlib.sha256(data).hexdigest()})
    report = {'schema': 'honor.g1.text-publication.v1', 'included': included, 'excluded': excluded}
    (out/'diagnostic-publication.json').write_text(json.dumps(report, indent=1)+'\n', encoding='utf-8')
    return report


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    report = prepare(args.source, args.out)
    print(json.dumps({'text_files': len(report['included']), 'excluded': len(report['excluded'])}))


if __name__ == '__main__':
    main()
