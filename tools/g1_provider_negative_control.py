#!/usr/bin/env python3
"""Darwin-only failure injection around real collector; no device execution."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

from g1_target_providers import write


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--imports', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--summary', type=Path, required=True)
    args = p.parse_args()
    # Run the real collect() and run_collection() in a fresh process. Only the
    # kernel nm command's response is fault-injected. Everything else uses the
    # native read-only path. No source edit, cached binary, or test success stub.
    child = '''
import sys
from pathlib import Path
from types import SimpleNamespace
import g1_target_providers as g
original = g.observe_binary
def fail_kernel(path, provider_id, level, names, out):
    if provider_id == 'runner-kernel':
        return original(path, provider_id, level, names, out,
            execute=lambda argv: (1, b'', b'intentional negative control: nm failed'))
    return original(path, provider_id, level, names, out)
g.observe_binary = fail_kernel
raise SystemExit(g.run_collection(SimpleNamespace(imports=Path(sys.argv[1]), out=Path(sys.argv[2]))))
'''
    result = subprocess.run([sys.executable, '-c', child, str(args.imports.resolve()), str(args.out.resolve())],
        cwd=Path(__file__).resolve().parent, capture_output=True, text=True, timeout=240)
    report = json.loads((args.out/'report.json').read_text(encoding='utf-8'))
    kernel = next(row for row in report['providers'] if row['id'] == 'runner-kernel')
    if (result.returncode != 2 or kernel['observation'] != 'NM_FAILED' or
            kernel['matches'] or report['required_evidence_gate']['status'] != 'FAILED'):
        raise ValueError('negative control failed to reject mandatory observation failure')
    summary = {'status': 'NEGATIVE_CONTROL_REJECTED_AS_REQUIRED', 'child_exit': result.returncode,
        'injected_fault': 'ONLY_KERNEL_NM_RESPONSE', 'kernel_observation': kernel,
        'required_evidence_gate': report['required_evidence_gate'],
        'child_stdout': result.stdout, 'child_stderr': result.stderr,
        'report_preserved': (args.out/'report.json').is_file(),
        'level': 'NATIVE_COLLECTOR_FAILURE_CONTRACT_NOT_DRIVER_EXECUTION'}
    write(args.summary, summary)
    print(json.dumps({'status': summary['status'], 'child_exit': result.returncode}))


if __name__ == '__main__':
    main()
