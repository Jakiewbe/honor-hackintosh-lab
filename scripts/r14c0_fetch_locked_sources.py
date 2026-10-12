#!/usr/bin/env python3
"""Fetch pinned public TEXT sources only; never run any upstream code.

Explicit network acquisition, separate from the offline validator. Existing
files must match their locks; mismatches are not overwritten. The source slice
is deliberately incomplete and cannot be compiled as a driver.
"""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request

from r14c0_validate_dependency_baseline import PINS, REPOS, blob_id, safe_path


def fetch(row, cache):
    if row['commit'] != PINS[row['component']] or row['repo'] != REPOS[row['component']]:
        raise ValueError('Invalid locked repository/version')
    dest = safe_path(cache / row['component'], row['path'])
    if dest.exists():
        data = dest.read_bytes()
    else:
        url = 'https://raw.githubusercontent.com/' + row['repo'] + '/' + row['commit'] + '/' + row['path']
        with urllib.request.urlopen(url, timeout=45) as response:
            data = response.read()
    data.decode('utf-8')
    if blob_id(data) != row['blob_sha'] or hashlib.sha256(data).hexdigest() != row['sha256']:
        raise ValueError('Source mismatch; stop, do not overwrite: ' + row['path'])
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation avoids races overwriting an intervening edit.
        with dest.open('xb') as f:
            f.write(data)
    return row['component'] + '/' + row['path']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lock', type=Path, default=Path('research/independent-i915/source-lock.json'))
    parser.add_argument('--cache', type=Path, default=Path('.cache'))
    args = parser.parse_args()
    lock = json.loads(args.lock.read_text(encoding='utf-8'))
    if {x['id']: x['commit'] for x in lock['components']} != PINS:
        raise ValueError('Component pins changed')
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        files = list(pool.map(lambda row: fetch(row, args.cache), lock['files']))
    print(json.dumps({'locked_text_files': len(files), 'compiled': 0, 'executed_upstream': 0}))


if __name__ == '__main__':
    main()
