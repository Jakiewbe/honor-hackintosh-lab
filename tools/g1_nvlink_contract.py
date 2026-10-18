#!/usr/bin/env python3
"""Compile the actual NVLink TU against mocked services; CPU only, never kext."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def execute(argv, log, timeout=60):
    result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=timeout)
    log.write_text('ARGV='+json.dumps(list(map(str, argv)))+'\n'+result.stdout+
                   '\nEXIT='+str(result.returncode)+'\n', encoding='utf-8')
    return result.returncode, result.stdout


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nv', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--cxx', default='clang++')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)  # stale outputs are never reused
    root = Path(__file__).resolve().parents[1]
    source = root/'research/gpu-safety-r5/darwin/nvlink_locks.cpp'
    fixtures = source.parent/'tests'
    shadow = args.out/'headers'
    for name in ['IOKit/IOLib.h', 'mach/semaphore.h', 'mach/sync_policy.h', 'kern/task.h', 'sys/systm.h']:
        header = shadow/name
        header.parent.mkdir(parents=True, exist_ok=True)
        header.write_text('#include "semaphore_fixture.h"\n', encoding='utf-8')
    includes = ['-I'+str(shadow), '-I'+str(fixtures)]
    for rel in ['src/common/nvlink/interface', 'src/common/inc', 'src/common/sdk/nvidia/inc']:
        includes += ['-isystem', str(args.nv.resolve()/rel)]
    flags = [args.cxx, '-std=c++17', '-pthread', '-Wall', '-Wextra', '-Werror', *includes]
    test = fixtures/'nvlink_locks_contract.cpp'
    binary = args.out/'nvlink-contract'
    report = {'level': 'CPU_MOCKED_SYSTEM_BOUNDARY_NOT_XNU_RUNTIME',
              'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'test_sha256': hashlib.sha256(test.read_bytes()).hexdigest()}
    rc, _ = execute([*flags, str(source), str(test), '-o', str(binary)], args.out/'compile.txt')
    report['compile_exit'] = rc
    if rc:
        report['run'] = 'NOT_RUN_COMPILE_FAILED'
    else:
        rc, stdout = execute([str(binary)], args.out/'run.txt', timeout=45)
        report.update({'run_exit': rc, 'summary': stdout.splitlines()[-1] if stdout else ''})
        if 'RESULT passed=17 failed=0 CPU_CONTRACT_ONLY' not in stdout:
            rc = 2
    if rc == 0:
        # Independent fresh output. Compilation error must not run an old binary.
        bad = args.out/'negative.cpp'
        bad.write_bytes(source.read_bytes()+b'\nthis is deliberately invalid C++;\n')
        bad_binary = args.out/'negative-contract'
        negative_rc, _ = execute([*flags, str(bad), str(test), '-o', str(bad_binary)], args.out/'negative-compile.txt')
        report['negative_compile'] = {'exit': negative_rc, 'binary_exists': bad_binary.exists(), 'run': 'NOT_RUN'}
        if negative_rc == 0 or bad_binary.exists():
            rc = 2
    report['status'] = 'PASS_CPU_ONLY' if rc == 0 else 'FAIL'
    (args.out/'report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report))
    return rc


if __name__ == '__main__':
    raise SystemExit(main())
