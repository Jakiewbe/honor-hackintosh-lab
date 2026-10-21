#!/usr/bin/env python3
"""Explicitly invoked passive diagnostics, never build/install/load or Metal enumeration."""
import argparse
import json
from pathlib import Path
import platform
import plistlib
import subprocess

import stock_v243_package as package


def pci_summary(raw):
    """Keep only target PCI IDs; never store a whole ioreg dump or serial properties."""
    roots = plistlib.loads(raw)
    rows = []
    pending = list(roots)
    while pending:
        entry = pending.pop()
        pending.extend(entry.get('IORegistryEntryChildren', []))
        def word(key):
            value = entry.get(key)
            return int.from_bytes(value[:2], 'little') if isinstance(value, bytes) and len(value) >= 2 else None
        vendor, device = word('vendor-id'), word('device-id')
        if (vendor, device) in ((0x10de, 0x25a9), (0x8086, 0x46a6)):
            rows.append(dict(vendor=f'{vendor:04x}', device=f'{device:04x}',
                evidence='PASSIVE_REGISTRY_ENTRY_NOT_INITIALIZATION_OR_METAL_PROOF'))
    return rows


def bound_inputs(products, report):
    if set(report.get('bundles', {})) != set(package.SPECS):
        raise ValueError('three-bundle build report required')
    for name in package.SPECS:
        actual = package.bundle_identity(products/(name+'.kext'))
        recorded = report['bundles'][name]
        if actual['bundle_sha256'] != recorded['sha256'] or actual['plist_sha256'] != recorded['plist_sha256']:
            raise ValueError('candidate/build-report identity differs: '+name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute-readonly', action='store_true')
    parser.add_argument('--bundles', required=True, type=Path)
    parser.add_argument('--build-report', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    if not args.execute_readonly or platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        parser.error('explicit read-only invocation on Intel Darwin required; no commands executed')
    report = dict(status='FAILED', device_load='NO_GO', gpu='NOT_RUN', stage='input-binding')
    args.out.mkdir(parents=True, exist_ok=False)
    try:
        products = args.bundles.resolve()
        build = json.loads(args.build_report.read_text())
        bound_inputs(products, build)
        report['build_report_sha256'] = package.base.digest(args.build_report)
        report['build_commit'] = build.get('commit')
        report['build_run_id'] = build.get('run_id')
        report['build_status'] = build.get('status')
        report['stage'] = 'passive-system-observation'
        # No root, no authentication bypass, no cache creation, no device enumeration API.
        for name, argv in (('system', ['/usr/bin/sw_vers']),
                           ('kernel', ['/usr/bin/uname', '-r', '-v', '-m']),
                           ('security', ['/usr/bin/csrutil', 'status']),
                           ('loaded-extensions', ['/usr/sbin/kextstat'])):
            package.base.checked_run(argv, products, args.out/(name+'.txt'))
        pci = subprocess.run(['/usr/sbin/ioreg', '-a', '-r', '-c', 'IOPCIDevice', '-d', '1'],
                             capture_output=True, timeout=60)
        if pci.returncode:
            raise ValueError('passive PCI registry command failed; exit='+str(pci.returncode))
        report['target_pci_entries'] = pci_summary(pci.stdout)
        report['stage'] = 'candidate-diagnostics'
        report['loader_dry_run'] = {}
        _, report['diagnostics'] = package.loader_diagnostics(products, args.out, report['loader_dry_run'])
        bound_inputs(products, build)
        if package.base.digest(args.build_report) != report['build_report_sha256']:
            raise ValueError('build report changed during observation')
        report.update(status='READONLY_DIAGNOSTICS_CAPTURED_NOT_DEVICE_ACCEPTANCE', stage='complete')
    except Exception as error:
        report['error'] = str(error)
    finally:
        package.base.save(args.out/'predevice-report.json', report)
    print(report['status'], report.get('error', ''))
    return 0 if report['status'] == 'READONLY_DIAGNOSTICS_CAPTURED_NOT_DEVICE_ACCEPTANCE' else 2


if __name__ == '__main__':
    raise SystemExit(main())
