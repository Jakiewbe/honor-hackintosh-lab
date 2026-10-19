#!/usr/bin/env python3
"""CPU-only adversarial contracts for the actual deferred-close unit.

No IOKit, no driver loading. Callback free counts are observations, not real
deallocations; a failing result does not prove a reachable kernel exploit.
Output directory must be fresh, so a failed build cannot execute a stale file.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

TEST = r'''
#include "kms_deferred.h"
#include <cstdio>
static int closes, frees, nested;
static kms_deferred_ops ops;
static void close_cb(void *, void *) { ++closes; }
static int free_cb(void *, void *) {
    ++frees;
    if (nested == 1) { nested = 2; kms_deferred_drain(&ops, 1, nullptr); }
    return 1;
}
int main() {
    ops.close = close_cb; ops.try_free = free_cb;
    int nodes[KMS_DEFERRED_CAPACITY + 1] = {};
    kms_deferred_reset();
    int first = kms_deferred_push(&nodes[0], &nodes[0]);
    int repeated = kms_deferred_push(&nodes[0], &nodes[0]);
    unsigned duplicate_count = kms_deferred_count();
    kms_deferred_drain(&ops, 1, nullptr);
    bool unique = first == 0 && repeated == 0 && duplicate_count == 1 && closes == 1 && frees == 1;
    std::printf("duplicate unique_node=%s entries=%u close_calls=%d free_calls=%d\n",
                unique ? "PASS" : "FAIL", duplicate_count, closes, frees);
    kms_deferred_reset(); closes = frees = 0; nested = 1;
    kms_deferred_push(&nodes[0], &nodes[0]);
    kms_deferred_drain(&ops, 1, nullptr);
    bool owned = closes == 1 && frees == 1 && kms_deferred_count() == 0;
    std::printf("reentrant unique_free=%s close_calls=%d free_calls=%d\n",
                owned ? "PASS" : "FAIL", closes, frees);
    kms_deferred_reset(); closes = frees = nested = 0;
    int overflow = 0;
    for (unsigned i = 0; i < KMS_DEFERRED_CAPACITY + 1; ++i)
        if (kms_deferred_push(&nodes[i], &nodes[i]) != 0) ++overflow;
    kms_deferred_drain(&ops, 1, nullptr);
    bool capacity = overflow == 1 && closes == KMS_DEFERRED_CAPACITY && frees == KMS_DEFERRED_CAPACITY;
    std::printf("capacity overflow_observable=%s unqueued=%d close_calls=%d free_calls=%d\n",
                capacity ? "PASS" : "FAIL", overflow, closes, frees);
    // This test verifies the queue's rejection, NOT a caller's recovery of it.
    return unique && owned && capacity ? 0 : 1;
}
'''


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--snapshot', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cxx', default='g++')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    unit = args.candidate / 'kexts/NVRM'
    snapshot = json.loads(args.snapshot.read_text(encoding='utf-8')) if args.snapshot else None
    hashes = {}
    for name in ('kms_deferred.cpp', 'kms_deferred.h'):
        hashes[name] = sha(unit / name)
        if snapshot:
            inputs = [r for r in snapshot['inputs'] if r['resolved_path'].endswith('/' + name)]
            if len(inputs) != 1 or hashes[name] != inputs[0]['sha256']:
                raise ValueError('actual CI dependency/source binding differs: ' + name)
    source = args.out / 'contract.cpp'
    source.write_text(TEST, encoding='utf-8')
    binary = args.out / 'contract'
    command = [args.cxx, '-std=c++17', '-Wall', '-Wextra', '-Werror',
               '-I' + str(unit), str(unit / 'kms_deferred.cpp'), str(source), '-o', str(binary)]
    compile_result = subprocess.run(command, capture_output=True, text=True)
    (args.out / 'compile.txt').write_text(compile_result.stdout + compile_result.stderr, encoding='utf-8')
    report = {'level': 'CPU_UNIT_ONLY_NOT_KERNEL_REACHABILITY', 'source_sha256': hashes,
              'snapshot_sha256': sha(args.snapshot) if args.snapshot else None,
              'binding': 'NATIVE_SNAPSHOT_MATCH' if snapshot else 'LOCAL_SOURCE_ONLY', 'compile_argv': command,
              'compile_exit': compile_result.returncode, 'run_exit': None,
              'run': 'NOT_RUN', 'status': 'COMPILE_FAILED'}
    if compile_result.returncode == 0 and binary.is_file():
        result = subprocess.run([str(binary)], capture_output=True, text=True)
        (args.out / 'run.txt').write_text(result.stdout + result.stderr, encoding='utf-8')
        report.update(run_exit=result.returncode, run='EXECUTED_NEW_BINARY',
                      status='PASS_CPU_UNIT_ONLY' if result.returncode == 0 else 'CONTRACT_FAIL')
    (args.out / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status'] == 'PASS_CPU_UNIT_ONLY' else 1


if __name__ == '__main__':
    raise SystemExit(main())
