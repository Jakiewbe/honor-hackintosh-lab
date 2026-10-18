#!/usr/bin/env python3
"""Read-only runner provider discovery. Global definitions are NOT KPI/ABI proof."""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import subprocess

from g1_symbol_identity import identity, parse_nm_undefined

IMPORTS_SHA256 = '0691e92bc5ef4ce537668c89a0c7b0c71238990aaeafc1c60125293e59fb9dc8'
SOURCE_COMMIT = 'c670c559cc4bd507f5efcb951dd428de250ba90c'
CANDIDATE_SHA256 = 'bbde79f1601ee7bc89bcef04f48dc45276d39f9dec9e3f8bbed456f157c1e1d3'
BUNDLES = ('System.kext', 'IOPCIFamily.kext', 'IOACPIFamily.kext')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=True)+'\n', encoding='utf-8')


def load_imports(path):
    data = path.read_bytes()
    if sha(data) != IMPORTS_SHA256:
        raise ValueError('frozen complete-candidate import inventory hash mismatch')
    names = parse_nm_undefined(data.decode('utf-8'))
    if len(names) != 472 or len(set(names)) != 472:
        raise ValueError('expected exactly 472 distinct frozen imports')
    return names


def parse_globals(text):
    """Strict Darwin nm -arch x86_64 -gU, single thin-selected binary.

    An indirect name is not an implementation; reject rather than count it.
    Unknown lines fail the whole observation, never partial acceptance.
    """
    result = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        m = re.fullmatch(r'\s*([0-9a-fA-F]+) ([ABCDRSTVW]) ([A-Za-z_.$][A-Za-z0-9_.$]*)\s*', line)
        if not m:
            raise ValueError('unrecognised or non-definition nm record: '+line[:180])
        _, kind, name = m.groups()
        if name in result:
            raise ValueError('duplicate nm global symbol')
        result[name] = kind
    return result


def match_records(names, providers):
    records = []
    for name in names:
        found = [dict(provider_id=p['id'], kind=p['matches'][name],
                      level=p['level']) for p in providers
                 if p.get('observation') == 'PARSED' and name in p.get('matches', {})]
        records.append(dict(identity(name), observations=found,
            status='GLOBAL_DEFINITION_OBSERVED_ONLY' if found else 'NOT_OBSERVED_IN_SCANNED_INPUTS',
            target_kpi_export='NOT_VERIFIED', abi='NOT_VERIFIED'))
    return records


def command(argv):
    try:
        p = subprocess.run(argv, capture_output=True, timeout=90)
        return p.returncode, p.stdout, p.stderr
    except (OSError, subprocess.TimeoutExpired) as error:
        return 125, b'', str(error).encode('utf-8')


def observe_binary(path, provider_id, level, names, out, execute=command):
    row = {'id': provider_id, 'path': str(path), 'level': level,
           'observation': 'NOT_PRESENT', 'matches': {}}
    if not path.is_file():
        return row
    try:
        raw = path.read_bytes()
        row.update(bytes=len(raw), sha256=sha(raw), real_path=str(path.resolve()))
        # Fileset kernel collections are only inventoried; nm global symbols do
        # not describe per-entry KPI visibility, so do not try to flatten them.
        argv = ['xcrun', 'nm', '-arch', 'x86_64', '-gU', str(path)]
        rc, stdout, stderr = execute(argv)
        row.update(argv=argv, exit=rc, stdout_sha256=sha(stdout), stderr_sha256=sha(stderr))
        diagnostic = stderr.decode('utf-8', errors='strict')
        row['diagnostic'] = diagnostic[:4000]
        if rc:
            row['observation'] = 'NM_FAILED'
        else:
            symbols = parse_globals(stdout.decode('utf-8', errors='strict'))
            row.update(observation='PARSED' if symbols else 'NO_GLOBAL_SYMBOLS',
                       global_symbol_count=len(symbols),
                       matches={n: symbols[n] for n in names if n in symbols})
        if sha(path.read_bytes()) != row['sha256']:
            raise ValueError('provider bytes changed during observation')
    except (OSError, UnicodeError, ValueError) as error:
        row.update(observation='OBSERVATION_FAILED', error=str(error), matches={})
    write(out/(provider_id+'.json'), row)
    return row


def inspect_bundle(bundle, label, names, out):
    plist_path = bundle/'Contents/Info.plist'
    if not plist_path.is_file():
        plist_path = bundle/'Info.plist'
    row = {'path': str(bundle), 'info_path': str(plist_path), 'state': 'NOT_PRESENT'}
    providers = []
    if not plist_path.is_file():
        return row, providers
    raw = plist_path.read_bytes()
    try:
        info = plistlib.loads(raw)
        row.update(state='INFO_READ', info_sha256=sha(raw),
            bundle_id=info.get('CFBundleIdentifier'), version=info.get('CFBundleVersion'),
            executable=info.get('CFBundleExecutable'), libraries=info.get('OSBundleLibraries'),
            required=info.get('OSBundleRequired'))
        executable = info.get('CFBundleExecutable')
        if executable:
            if not isinstance(executable, str) or '/' in executable or '\\' in executable or executable in ('.', '..'):
                raise ValueError('unsafe bundle executable basename')
            binary = bundle/'Contents/MacOS'/executable
            if not binary.is_file() and (bundle/executable).is_file():
                binary = bundle/executable
            p = observe_binary(binary, label,
                'RUNNER_KEXT_GLOBAL_DEFINITION_NOT_LOAD_OR_ABI_PROOF', names, out)
            p['bundle_id'], p['bundle_version'] = row['bundle_id'], row['version']
            providers.append(p)
    except (ValueError, TypeError, plistlib.InvalidFileException) as error:
        row.update(state='INFO_FAILED', error=str(error))
    return row, providers


def inventory_tree(root, depth=4):
    """Bounded metadata discovery, never read executable contents into output."""
    result = {'root': str(root), 'present': root.exists(), 'files': []}
    if not root.is_dir():
        return result
    for base, directories, files in os.walk(root, followlinks=False):
        relative = Path(base).relative_to(root)
        directories.sort()
        if len(relative.parts) >= depth:
            directories[:] = []
        for name in sorted(files):
            path = Path(base)/name
            stat = path.stat()
            result['files'].append({'path': path.relative_to(root).as_posix(), 'bytes': stat.st_size,
                                    'symlink': path.is_symlink()})
    return result


def collect(args, out):
    if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        raise ValueError('read-only Intel Darwin runner required')
    names = load_imports(args.imports)
    env = {}
    for key, argv in [('os', ['sw_vers']), ('kernel', ['uname', '-r']),
                      ('sdk', ['xcrun', '--show-sdk-path']), ('sdk_version', ['xcrun', '--show-sdk-version']),
                      ('xcode', ['xcodebuild', '-version']), ('nm', ['xcrun', 'nm', '--version'])]:
        rc, stdout, stderr = command(argv)
        env[key] = {'argv': argv, 'exit': rc, 'stdout': stdout.decode('utf-8'), 'stderr': stderr.decode('utf-8')}
        if rc:
            raise ValueError('toolchain identity query failed: '+key)
    sdk = Path(env['sdk']['stdout'].strip())
    providers = [observe_binary(Path('/System/Library/Kernels/kernel'), 'runner-kernel',
        'RUNNER_KERNEL_GLOBAL_DEFINITION_NOT_KPI_EXPORT_PROOF', names, out)]
    bundles = []
    for name in BUNDLES:
        bundle = Path('/System/Library/Extensions')/name
        candidates = [bundle, *sorted((bundle/'Contents/PlugIns').glob('*.kext')),
                      *sorted((bundle/'PlugIns').glob('*.kext'))]
        for i, candidate in enumerate(candidates):
            row, observed = inspect_bundle(candidate, name.replace('.', '-')+'-'+str(i), names, out)
            bundles.append(row)
            providers.extend(observed)
    # Inventory SDK libraries/stubs and KC paths separately; do not call SDK
    # declarations, tbd text, allowlists or kernel globals actual target exports.
    roots = [sdk/'System/Library/Frameworks/Kernel.framework',
             sdk/'System/Library/Frameworks/Kernel.framework/Versions/A/Libraries',
             sdk/'System/Library/Extensions', Path('/System/Library/Kernels'),
             Path('/System/Library/KernelCollections'), Path('/Library/Apple/System/Library/KernelCollections'),
             *[Path('/System/Library/Extensions')/name for name in BUNDLES]]
    inventory = [inventory_tree(root) for root in roots]
    rc, stdout, stderr = command(['/usr/bin/kmutil', 'inspect', '--help'])
    write(out/'kmutil-inspect-help.json', {'argv': ['/usr/bin/kmutil', 'inspect', '--help'],
        'exit': rc, 'stdout': stdout.decode('utf-8'), 'stderr': stderr.decode('utf-8')})
    records = match_records(names, providers)
    report = {'schema': 'honor.g1.runner-provider-discovery.v1',
        'status': 'DISCOVERY_COMPLETE_NOT_TARGET_KPI_OR_ABI_ACCEPTANCE',
        'source_commit': os.environ.get('GITHUB_SHA'), 'environment': env,
        'frozen_candidate': {'source_commit': SOURCE_COMMIT, 'run_id': 39127772586,
            'candidate_sha256': CANDIDATE_SHA256, 'imports_sha256': IMPORTS_SHA256,
            'rebuild_in_this_run': False},
        'scope': 'RUNNER_OS_ONLY_NOT_USER_TARGET_SYSTEM', 'providers': providers,
        'bundle_metadata': bundles, 'inventory': inventory, 'records': records,
        'counts': dict(Counter(r['status'] for r in records)),
        'target_export_abi_acceptance': 'NOT_VERIFIED', 'kext_load': 'NO-GO', 'gpu_execution': False}
    write(out/'report.json', report)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--imports', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    try:
        report = collect(args, args.out)
        print(json.dumps({'status': report['status'], 'counts': report['counts']}))
        return 0
    except Exception as error:
        write(args.out/'failure.json', {'status': 'DISCOVERY_FAILED', 'error': str(error),
            'kext_load': 'NO-GO', 'target_export_abi_acceptance': 'NOT_VERIFIED'})
        raise


if __name__ == '__main__':
    raise SystemExit(main())
