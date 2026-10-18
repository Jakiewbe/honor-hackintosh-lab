#!/usr/bin/env python3
"""Retired incomplete directory-scan probe. Use the official complete-build gate."""
import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--nv')  # Compatibility only; never inspected or executed.
    parser.add_argument('--sdk')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    report = {'status': 'RETIRED_INCOMPLETE_PROBE_NOT_A_BUILD_GATE',
        'reason': '988 directory entries and placeholder macros are not the official source/flag inventory; partial links cannot establish completeness',
        'superseded_by': 'tools/g1_full_build.py / gpu-safety-r5-native.yml',
        'prior_run': 39138580661, 'prior_compiled': 135, 'prior_files': 988,
        'compile': 'NOT_ATTEMPTED', 'link': 'NOT_ATTEMPTED', 'kext_load': 'NO-GO'}
    (args.out/'report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(report['status'])
    return 2


if __name__ == '__main__': raise SystemExit(main())
