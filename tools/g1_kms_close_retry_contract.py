#!/usr/bin/env python3
"""R32 real-function CPU contracts. Injected IOKit/NVKMS; never kernel/GPU execution.

Fresh output required. Optional native snapshots bind the whole selected source
and queue inputs; without snapshots the evidence is explicitly LOCAL_SOURCE_ONLY.
Deterministic callback/PM schedules exercise real bodies, not XNU scheduling.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from g1_kms_close_contract import function

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
using NvBool = int;
using thread_call_t = void *;
using thread_call_param_t = void *;
struct IOLock {};
struct NvKmsKapiDevice {};
enum NvKmsClientType { NVKMS_CLIENT_USER_SPACE, NVKMS_CLIENT_KERNEL_SPACE };
enum { NV_TRUE = 1, NV_FALSE = 0 };
enum { kKmsPmRunning, kKmsPmSuspended, kKmsPmLost };
enum { THREAD_UNINT, THREAD_TIMED_OUT, kMillisecondScale };
static IOLock lock_object;
static IOLock *gKmsLock = &lock_object;
static bool gKmsLoaded = true, gKmsSuspendPending;
static uint32_t gKmsSuspendSeq;
static int gKmsPmState, gKmsPmPins;
static volatile uint32_t gKmsCloseDeferred, gKmsCloseDeferredLost;
static const uint32_t kKmsPmWaitMs = 30000;
static const char *const kKmsPmName[] = {"running", "suspended", "lost"};
static int worker_id;
// RETRY_STATE_FROM_SOURCE
static int backend_closes, wrapper_frees, sleeps, deadline_sleeps, schedules, event_runs, lock_depth;
static bool event_free_ok = true, cancel_ok, rm_closed;
static void require(bool ok, const char *message) { if (!ok) throw std::runtime_error(message); }
static void IOLockLock(IOLock *) { require(lock_depth == 0, "recursive KMS lock"); ++lock_depth; }
static void IOLockUnlock(IOLock *) { require(lock_depth == 1, "unlock without lock"); --lock_depth; }
static int IOLockSleep(IOLock *, void *, int) { ++sleeps; throw std::runtime_error("unbounded callback sleep"); }
static int IOLockSleepDeadline(IOLock *, void *, uint64_t, int) { ++deadline_sleeps; return THREAD_TIMED_OUT; }
static void IOLockWakeup(IOLock *, void *, bool) { require(lock_depth == 1, "wakeup outside lock"); }
static void clock_interval_to_deadline(uint32_t ms, int, uint64_t *out) { *out = ms; }
static bool thread_call_cancel(thread_call_t) { require(lock_depth == 1, "cancel outside lock"); return cancel_ok; }
static bool thread_call_free(thread_call_t) { require(lock_depth == 1, "free outside lock"); return event_free_ok; }
static bool thread_call_enter_delayed(thread_call_t call, uint64_t deadline) {
    require(lock_depth == 1 && call == gKmsCloseWorker && deadline == 100, "bad retry schedule");
    ++schedules; return false;
}
static void nvKmsClose(void *) { require(lock_depth == 1 && !rm_closed, "backend close with gate shut/outside lock"); ++backend_closes; }
static void nvkms_free(void *, size_t) { require(lock_depth == 1, "wrapper free outside lock"); ++wrapper_frees; }
static void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *) { ++event_runs; }
static void nvKmsKapiSuspendResume(NvBool) {}
static void nvKmsResume(NvU32) {}
static int kprintf(const char *, ...) { return 0; }
'''

SUFFIX = r'''
static nvkms_per_open node, other;
static int data, data2;
static void init(nvkms_per_open &n, int *d) { n = {}; n.data = d; n.eventCall = d; }
static void tick() { kms_close_retry_fire(nullptr, nullptr); }
static void after_resume(bool ok = true) {
    rm_closed = true;
    nvkms_xnu_resume(1, ok);
    // An already queued worker racing the PM owner must not touch RM here.
    tick();
    require(backend_closes == 0 && wrapper_frees == 0, "reaped before RM gate open");
    rm_closed = false;
    nvkms_xnu_reap_closes();
}
static void complete() {
    require(backend_closes == 1 && wrapper_frees == 1 && kms_deferred_count() == 0,
            "close/free obligation not completed exactly once");
    require(gKmsCloseDeferred == 0 && sleeps == 0 && lock_depth == 0, "counter/sleep/lock failure");
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    const char *name = argv[1];
    gKmsCloseWorker = &worker_id;
    init(node, &data); init(other, &data2);
    try {
        if (std::strcmp(name, "suspended-retain") == 0) {
            gKmsPmState = kKmsPmSuspended;
            kms_close_common(&node);
            require(backend_closes == 0 && wrapper_frees == 0 && kms_deferred_count() == 1 &&
                    deadline_sleeps == 1 && schedules == 0 && gKmsCloseDeferred == 1, "suspend retention");
        } else if (std::strcmp(name, "deferred-recover") == 0 || std::strcmp(name, "gate-before-reap") == 0) {
            gKmsPmState = kKmsPmLost;
            kms_close_common(&node);
            after_resume(); tick(); complete(); tick(); complete();
        } else if (std::strcmp(name, "normal-free-failure") == 0) {
            event_free_ok = false;
            kms_close_common(&node);
            require(backend_closes == 1 && wrapper_frees == 0 && kms_deferred_count() == 1 &&
                    schedules == 1 && gKmsCloseDeferred == 0, "normal retained wrapper untracked/counter polluted");
            tick(); tick();
            require(backend_closes == 1 && wrapper_frees == 0 && kms_deferred_count() == 1 && schedules == 3,
                    "retry lost ownership/repeated backend close");
            event_free_ok = true; tick(); complete();
        } else if (std::strcmp(name, "stalled-callback") == 0 || std::strcmp(name, "normal-busy") == 0) {
            bool deferred = std::strcmp(name, "stalled-callback") == 0;
            if (deferred) gKmsPmState = kKmsPmLost;
            node.eventBusy = true;
            kms_close_common(&node);
            if (deferred) after_resume();
            tick(); tick();
            require(backend_closes == 1 && wrapper_frees == 0 && kms_deferred_count() == 1 && sleeps == 0,
                    "busy callback was waited/freed/double-closed");
            kms_kapi_event_fire(&node, nullptr);
            require(event_runs == 0 && !node.eventBusy, "closing event invoked KAPI/rearmed");
            tick(); complete();
        } else if (std::strcmp(name, "cancel-pending") == 0) {
            node.eventBusy = true; cancel_ok = true;
            kms_close_common(&node); complete();
            require(schedules == 0, "cancelled callback left a backlog");
        } else if (std::strcmp(name, "pending-abort") == 0) {
            gKmsPmState = kKmsPmLost; kms_close_common(&node);
            gKmsPmState = kKmsPmRunning; gKmsSuspendPending = true; gKmsSuspendSeq = 3;
            tick(); require(backend_closes == 0 && schedules == 0, "pending suspend admitted retry");
            nvkms_xnu_suspend_abort(3);
            require(schedules == 1, "abort did not rearm backlog");
            tick(); complete();
        } else if (std::strcmp(name, "lost-no-retry") == 0) {
            gKmsPmState = kKmsPmLost; kms_close_common(&node);
            after_resume(false); tick();
            require(backend_closes == 0 && wrapper_frees == 0 && kms_deferred_count() == 1 && schedules == 0,
                    "lost GPU reclaimed/retried");
        } else if (std::strcmp(name, "repeat-close") == 0) {
            event_free_ok = false; kms_close_common(&node); kms_close_common(&node);
            require(backend_closes == 1 && kms_deferred_count() == 1, "second close created another owner");
            event_free_ok = true; tick(); complete();
        } else if (std::strcmp(name, "counter-isolation") == 0) {
            gKmsPmState = kKmsPmLost; node.eventBusy = true; kms_close_common(&node);
            gKmsPmState = kKmsPmRunning; event_free_ok = false; kms_close_common(&other);
            event_free_ok = true; tick();
            require(gKmsCloseDeferred == 1 && wrapper_frees == 1 && kms_deferred_count() == 1,
                    "normal wrapper consumed a refused-backend counter");
            kms_kapi_event_fire(&node, nullptr); tick();
            require(backend_closes == 2 && wrapper_frees == 2 && kms_deferred_count() == 0 &&
                    gKmsCloseDeferred == 0, "deferred counter did not recover");
        } else if (std::strcmp(name, "worker-unavailable") == 0) {
            gKmsCloseWorker = nullptr; event_free_ok = false; kms_close_common(&node);
            require(wrapper_frees == 0 && kms_deferred_count() == 1 && schedules == 0, "missing worker freed argument");
        } else if (std::strcmp(name, "stable-deadline") == 0) {
            event_free_ok = false;
            kms_close_common(&node); kms_close_common(&other);
            require(schedules == 1 && kms_deferred_count() == 2, "new arrival postponed armed deadline");
            event_free_ok = true; tick();
            require(backend_closes == 2 && wrapper_frees == 2 && kms_deferred_count() == 0 && sleeps == 0,
                    "batched normal wrapper reclaim failed");
        } else return 2;
        std::printf("%s PASS close=%d free=%d queued=%u schedules=%d sleeps=%d counter=%u\n",
            name, backend_closes, wrapper_frees, kms_deferred_count(), schedules, sleeps, gKmsCloseDeferred);
        return 0;
    } catch (const std::exception &error) {
        std::printf("%s FAIL %s close=%d free=%d queued=%u\n", name, error.what(),
                    backend_closes, wrapper_frees, kms_deferred_count());
        return 1;
    }
}
'''

NAMES = [
    'static bool kms_pm_wait_locked(bool tryOnly, uint32_t waitMs)',
    'static void kms_close_retry_schedule_locked(void)',
    'static void kms_deferred_close_impl(void *data, void *)',
    'static int kms_deferred_try_free_impl(void *node, void *)',
    'static void kms_close_retry_fire(thread_call_param_t, thread_call_param_t)',
    'static void kms_close_remember_locked(struct nvkms_per_open *popen)',
    'static void kms_close_common(struct nvkms_per_open *popen)',
    'static void kms_kapi_event_fire(thread_call_param_t p0, thread_call_param_t)',
    'void nvkms_xnu_suspend_abort(uint32_t seq)',
    'void nvkms_xnu_resume(NvU32 gpuId, NvBool gpuOk)',
    'void nvkms_xnu_reap_closes(void)',
]
SCENARIOS = ('suspended-retain', 'deferred-recover', 'normal-free-failure', 'stalled-callback',
             'cancel-pending', 'pending-abort', 'lost-no-retry',
             'repeat-close', 'counter-isolation', 'gate-before-reap', 'worker-unavailable', 'stable-deadline')


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def bind(snapshot, unit, names):
    data = json.loads(snapshot.read_text(encoding='utf-8'))
    for name in names:
        entries = [r for r in data['inputs'] if r['resolved_path'].endswith('/'+name)]
        if len(entries) != 1 or entries[0]['sha256'] != sha(unit/name):
            raise ValueError('actual native source binding differs: '+name)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate', type=Path, required=True)
    p.add_argument('--os-snapshot', type=Path)
    p.add_argument('--queue-snapshot', type=Path)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--cxx', default='g++')
    p.add_argument('--negative-compile', action='store_true')
    p.add_argument('--open-normal-busy', action='store_true',
                   help='Run only the known OPEN normal-close join; failure remains exit 1')
    args = p.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    unit = args.candidate/'kexts/NVRM'
    if bool(args.os_snapshot) != bool(args.queue_snapshot):
        raise ValueError('both snapshots required together')
    if args.os_snapshot:
        bind(args.os_snapshot, unit, ('os-nvkms-xnu.cpp',))
        bind(args.queue_snapshot, unit, ('kms_deferred.cpp', 'kms_deferred.h'))
    text = (unit/'os-nvkms-xnu.cpp').read_text(encoding='utf-8')
    start = text.index('struct nvkms_per_open {')
    end = text.index('\n};', start)+3
    parts = [function(text, name) for name in NAMES]
    ops_start = text.index('static const struct kms_deferred_ops kKmsDeferredOps = {')
    ops_end = text.index('\n};', ops_start)+3
    parts.insert(4, text[ops_start:ops_end])
    source = args.out/'fixture.cpp'
    declarations = []
    for prefix in ('static thread_call_t gKmsCloseWorker;', 'static bool gKmsCloseRetryReady',
                   'static bool gKmsCloseRetryArmed;', 'static const uint32_t kKmsCloseRetryMs', 'static const uint32_t kKmsCloseJoinMs'):
        lines = [line for line in text.splitlines() if line.startswith(prefix)]
        if len(lines) != 1: raise ValueError('retry state definition differs: '+prefix)
        declarations.append(lines[0])
    fixture_prefix = PREFIX.replace('// RETRY_STATE_FROM_SOURCE', '\n'.join(declarations))
    source.write_text(fixture_prefix+'\n'+text[start:end]+'\n'+'\n\n'.join(parts)+'\n'+
                      ('#error NEGATIVE_COMPILE_CONTROL\n' if args.negative_compile else '')+SUFFIX,
                      encoding='utf-8')
    binary = args.out/'fixture'
    command = [args.cxx, '-std=c++17', '-Wall', '-Wextra', '-Werror', '-I'+str(unit),
               str(unit/'kms_deferred.cpp'), str(source), '-o', str(binary)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    (args.out/'compile.txt').write_text(result.stdout+result.stderr, encoding='utf-8')
    report = {'level':'REAL_FUNCTIONS_CPU_INJECTED_BOUNDARIES_NOT_XNU_RUNTIME',
        'binding':'NATIVE_SNAPSHOTS_MATCH' if args.os_snapshot else 'LOCAL_SOURCE_ONLY',
        'source_sha256':{n:sha(unit/n) for n in ('os-nvkms-xnu.cpp','kms_deferred.cpp','kms_deferred.h','NVRM.cpp')},
        'snapshot_sha256':{n:sha(v) for n,v in [('os',args.os_snapshot),('queue',args.queue_snapshot)] if v},
        'fixture_sha256':sha(source),'functions':NAMES,'compile_argv':command,
        'compile_exit':result.returncode,'scenarios':[],'status':'COMPILE_FAILED',
        'negative_compile':args.negative_compile,'binary_exists':binary.is_file()}
    if result.returncode == 0 and binary.is_file():
        for name in (('normal-busy',) if args.open_normal_busy else SCENARIOS):
            result = subprocess.run([str(binary),name],capture_output=True,text=True,timeout=10)
            output = result.stdout+result.stderr
            (args.out/(name+'.txt')).write_text(output, encoding='utf-8')
            report['scenarios'].append({'scenario':name,'exit':result.returncode,'output':output})
        report['status'] = 'PASS_CPU_ONLY' if all(r['exit'] == 0 for r in report['scenarios']) else 'CONTRACT_FAIL'
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))
    return 0 if report['status'] == 'PASS_CPU_ONLY' else 1


if __name__ == '__main__': raise SystemExit(main())
