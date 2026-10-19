#!/usr/bin/env python3
"""CPU contracts from complete actual NVKMS close/wait/free functions.

IOKit/NVKMS boundary services are injected. No kernel/device execution. A
stalled callback is stopped by the mock after three sleep iterations, so FAIL
means the actual loop lacks a bound under that injection, not an observed XNU
deadlock. Each scenario runs in a fresh process; failed compilation never runs.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

PREFIX = r'''
// Extracted driver functions: Copyright (c) 2026 NullMoth Systems.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#include <cstdint>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include "kms_deferred.h"
using NvU32 = uint32_t;
using thread_call_t = void *;
struct IOLock {};
struct NvKmsKapiDevice;
enum NvKmsClientType { NVKMS_CLIENT_USER_SPACE, NVKMS_CLIENT_KERNEL_SPACE };
enum { kKmsPmRunning, kKmsPmSuspended, kKmsPmLost };
enum { THREAD_UNINT, THREAD_TIMED_OUT, kMillisecondScale };
static IOLock lock_object;
static IOLock *gKmsLock = &lock_object;
static int gKmsPmState;
static volatile uint32_t gKmsCloseDeferred, gKmsCloseDeferredLost;
static const uint32_t kKmsPmWaitMs = 30000;
static const char *const kKmsPmName[] = {"running", "suspended", "lost"};
static int backend_closes, wrapper_frees, sleeps, deadline_sleeps;
static bool event_free_ok = true;
static void IOLockLock(IOLock *) {}
static void IOLockUnlock(IOLock *) {}
static int IOLockSleep(IOLock *, void *, int) {
    if (++sleeps == 3) throw std::runtime_error("STALLED_CALLBACK: 3 unbounded sleep iterations");
    return 0;
}
static int IOLockSleepDeadline(IOLock *, void *, uint64_t, int) { ++deadline_sleeps; return THREAD_TIMED_OUT; }
static void clock_interval_to_deadline(uint32_t ms, int, uint64_t *out) { *out = ms; }
static bool thread_call_cancel(thread_call_t) { return false; }
static bool thread_call_free(thread_call_t) { return event_free_ok; }
static void nvKmsClose(void *) { ++backend_closes; }
static void nvkms_free(void *, size_t) { ++wrapper_frees; } // Counts only: no real memory deletion.
static int kprintf(const char *, ...) { return 0; }
'''

SUFFIX = r'''
static const kms_deferred_ops ops = {kms_deferred_close_impl, kms_deferred_try_free_impl};
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int data;
    nvkms_per_open node = {};
    node.data = &data;
    node.eventCall = &data;
    if (std::strcmp(argv[1], "normal-free-failure") == 0) {
        gKmsPmState = kKmsPmRunning;
        event_free_ok = false;
        kms_close_common(&node);
        bool tracked = backend_closes == 1 && wrapper_frees == 0 && kms_deferred_count() == 1;
        std::printf("normal-free-failure %s close=%d free=%d queued=%u\n",
                    tracked ? "PASS" : "FAIL", backend_closes, wrapper_frees, kms_deferred_count());
        return tracked ? 0 : 1;
    }
    if (std::strcmp(argv[1], "suspended-retain") == 0) {
        gKmsPmState = kKmsPmSuspended;
        kms_close_common(&node);
        bool kept = backend_closes == 0 && wrapper_frees == 0 && kms_deferred_count() == 1 && deadline_sleeps == 1;
        std::printf("suspended-retain %s close=%d free=%d queued=%u deadline_waits=%d\n",
                    kept ? "PASS" : "FAIL", backend_closes, wrapper_frees, kms_deferred_count(), deadline_sleeps);
        return kept ? 0 : 1;
    }
    bool stalled = std::strcmp(argv[1], "stalled-callback") == 0;
    if (!stalled && std::strcmp(argv[1], "deferred-recover") != 0) return 2;
    gKmsPmState = kKmsPmLost;
    node.eventBusy = stalled;
    kms_close_common(&node);
    gKmsPmState = kKmsPmRunning;
    try {
        kms_deferred_drain(&ops, 1, nullptr);
    } catch (const std::runtime_error &error) {
        std::printf("stalled-callback FAIL %s close=%d free=%d queued=%u\n",
                    error.what(), backend_closes, wrapper_frees, kms_deferred_count());
        return 1;
    }
    bool done = backend_closes == 1 && wrapper_frees == 1 && kms_deferred_count() == 0;
    std::printf("%s %s close=%d free=%d queued=%u\n", argv[1], done ? "PASS" : "FAIL",
                backend_closes, wrapper_frees, kms_deferred_count());
    return done ? 0 : 1;
}
'''


def function(text, name):
    # The four specific definitions are selected by exact signature. This is
    # not a general C++ parser: reject unexpected unmatched braces.
    if text.count(name) != 1:
        raise ValueError('expected one exact definition: '+name)
    start = text.index(name)
    opening = text.index('{', start)
    depth = 0
    for at in range(opening, len(text)):
        if text[at] == '{': depth += 1
        elif text[at] == '}':
            depth -= 1
            if depth == 0: return text[start:at+1]
    raise ValueError('unbalanced selected function')


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate', type=Path, required=True)
    p.add_argument('--os-snapshot', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--cxx', default='g++')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    unit = args.candidate/'kexts/NVRM'
    path = unit/'os-nvkms-xnu.cpp'
    snapshot = json.loads(args.os_snapshot.read_text(encoding='utf-8'))
    entries = [r for r in snapshot['inputs'] if r['resolved_path'].endswith('/os-nvkms-xnu.cpp')]
    if len(entries) != 1 or entries[0]['sha256'] != sha(path):
        raise ValueError('actual native OS source binding differs')
    text = path.read_text(encoding='utf-8')
    struct_start = text.index('struct nvkms_per_open {')
    struct_end = text.index('\n};', struct_start)+3
    names = ['static bool kms_pm_wait_locked(bool tryOnly, uint32_t waitMs)',
             'static void kms_close_common(struct nvkms_per_open *popen)',
             'static void kms_deferred_close_impl(void *data, void *)',
             'static int kms_deferred_try_free_impl(void *node, void *)']
    bodies = [function(text, name) for name in names]
    source = args.out/'fixture.cpp'
    source.write_text(PREFIX+'\n'+text[struct_start:struct_end]+'\n'+'\n\n'.join(bodies)+'\n'+SUFFIX, encoding='utf-8')
    binary = args.out/'fixture'
    command = [args.cxx,'-std=c++17','-Wall','-Wextra','-Werror','-I'+str(unit),
               str(unit/'kms_deferred.cpp'),str(source),'-o',str(binary)]
    compile_result = subprocess.run(command,capture_output=True,text=True)
    (args.out/'compile.txt').write_text(compile_result.stdout+compile_result.stderr,encoding='utf-8')
    report = {'level':'REAL_FUNCTIONS_CPU_INJECTED_BOUNDARIES_NOT_XNU_RUNTIME',
        'os_source_sha256':sha(path),'os_snapshot_sha256':sha(args.os_snapshot),
        'queue_sha256':sha(unit/'kms_deferred.cpp'),'fixture_sha256':sha(source),
        'compile_argv':command,'compile_exit':compile_result.returncode,'scenarios':[],'status':'COMPILE_FAILED'}
    if compile_result.returncode == 0 and binary.is_file():
        for scenario in ('suspended-retain','deferred-recover','normal-free-failure','stalled-callback'):
            result = subprocess.run([str(binary),scenario],capture_output=True,text=True,timeout=10)
            output = result.stdout+result.stderr
            (args.out/(scenario+'.txt')).write_text(output,encoding='utf-8')
            report['scenarios'].append({'scenario':scenario,'exit':result.returncode,'output':output})
        report['status'] = 'PASS_CPU_ONLY' if all(r['exit'] == 0 for r in report['scenarios']) else 'CONTRACT_FAIL'
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status'] == 'PASS_CPU_ONLY' else 1


if __name__ == '__main__': raise SystemExit(main())
