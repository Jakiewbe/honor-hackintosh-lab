
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
static thread_call_t gKmsCloseWorker;
static bool gKmsCloseRetryReady = true;
static bool gKmsCloseRetryArmed;
static const uint32_t kKmsCloseRetryMs = 100;
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

struct nvkms_per_open {
    void *data;
    enum NvKmsClientType type;
    struct NvKmsKapiDevice *device;
    thread_call_t eventCall;
    bool eventBusy, eventWanted, closing;
    bool deferredCounted; // Only a refused backend close contributes to the old teardown counter.
    volatile int eventsAvailable;
};
static bool kms_pm_wait_locked(bool tryOnly, uint32_t waitMs)
{
    if (gKmsPmState == kKmsPmRunning) return true;
    if (tryOnly || gKmsPmState == kKmsPmLost) return false;
    uint64_t deadline = 0;
    if (waitMs) clock_interval_to_deadline(waitMs, kMillisecondScale, &deadline);
    while (gKmsPmState == kKmsPmSuspended) {
        int wr = waitMs ? IOLockSleepDeadline(gKmsLock, &gKmsPmState, deadline, THREAD_UNINT)
                        : IOLockSleep(gKmsLock, &gKmsPmState, THREAD_UNINT);
        if (wr == THREAD_TIMED_OUT) break;
    }
    return gKmsPmState == kKmsPmRunning;
}

static void kms_close_retry_schedule_locked(void)
{
    if (!gKmsCloseWorker || gKmsCloseRetryArmed || !gKmsCloseRetryReady || gKmsSuspendPending ||
        gKmsPmState != kKmsPmRunning || kms_deferred_count() == 0) return;
    uint64_t deadline;
    clock_interval_to_deadline(kKmsCloseRetryMs, kMillisecondScale, &deadline);
    gKmsCloseRetryArmed = true; // New arrivals must not keep postponing an already armed deadline.
    thread_call_enter_delayed(gKmsCloseWorker, deadline);
}

static void kms_deferred_close_impl(void *data, void *)
{
    nvKmsClose(data);
}

static int kms_deferred_try_free_impl(void *node, void *)
{
    struct nvkms_per_open *popen = (struct nvkms_per_open *)node;
    if (popen->eventCall && popen->eventBusy) {
        if (thread_call_cancel(popen->eventCall)) popen->eventBusy = false;
        if (popen->eventBusy) return 0; // The worker may be waiting for RM; never join it here.
    }
    if (popen->eventCall && !thread_call_free(popen->eventCall)) return 0;
    // A successful thread_call_free is not a join. eventBusy became false under this same lock;
    // after unlocking, the closing event callback returns without accessing popen again.
    popen->eventCall = NULL;
    popen->data = NULL;
    if (popen->deferredCounted && gKmsCloseDeferred) gKmsCloseDeferred--;
    nvkms_free(popen, sizeof *popen);
    return 1;
}

static const struct kms_deferred_ops kKmsDeferredOps = {
    kms_deferred_close_impl,
    kms_deferred_try_free_impl,
};

static void kms_close_retry_fire(thread_call_param_t, thread_call_param_t)
{
    IOLockLock(gKmsLock);
    gKmsCloseRetryArmed = false;
    if (gKmsCloseRetryReady && !gKmsSuspendPending && gKmsPmState == kKmsPmRunning) {
        kms_deferred_drain(&kKmsDeferredOps, 1, NULL);
        kms_close_retry_schedule_locked();
    }
    IOLockUnlock(gKmsLock);
}

static void kms_close_remember_locked(struct nvkms_per_open *popen)
{
    if (kms_deferred_push(popen, popen->data) != 0) {
        // Capacity exhaustion is still unresolved: keep memory alive, report, never claim reclamation.
        kprintf("NVRM-xnu: deferred-close table full/conflicting; wrapper retained without a queue slot\n");
    }
    kms_close_retry_schedule_locked();
}

static void kms_close_common(struct nvkms_per_open *popen)
{
    if (!popen) return;
    IOLockLock(gKmsLock);
    if (popen->closing) { IOLockUnlock(gKmsLock); return; }
    popen->closing = true;
    popen->eventWanted = false;
    // nvidia-modeset-os-interface.h: NVKMS keeps the pointer handed to nvKmsOpen() as pOpenKernel and
    // still passes it back to nvkms_event_queue_changed() until nvKmsClose() has destroyed that
    // per-open. While the GPU is suspended or lost nvKmsClose() must not touch the display engine
    // (a push to a core channel nobody serves spins in nvEvoMakeRoom), so a failed wait is not a
    // completed close: keep the per-open, this wrapper and its event worker allocated, refuse new
    // work, and never hand back memory NVKMS still points at.
    if (!kms_pm_wait_locked(false, kKmsPmWaitMs)) {
        popen->deferredCounted = true;
        gKmsCloseDeferred++;
        if (gKmsPmState == kKmsPmLost) gKmsCloseDeferredLost++;
        const int state = gKmsPmState;
        const unsigned deferred = gKmsCloseDeferred, lost = gKmsCloseDeferredLost;
        kms_close_remember_locked(popen);
        IOLockUnlock(gKmsLock);
        kprintf("NVRM-xnu: NVKMS close deferred while the GPU is %s: per-open and wrapper kept (deferred #%u, lost #%u)\n",
                kKmsPmName[state], deferred, lost);
        return;
    }
    if (popen->data) nvKmsClose(popen->data);
    popen->data = NULL;
    // If the callback is still running or its call cannot be released, the queue becomes the sole
    // wrapper owner. A NULL data entry is already backend-closed and must not call nvKmsClose again.
    if (!kms_deferred_try_free_impl(popen, NULL)) kms_close_remember_locked(popen);
    IOLockUnlock(gKmsLock);
}

static void kms_kapi_event_fire(thread_call_param_t p0, thread_call_param_t)
{
    struct nvkms_per_open *popen = (struct nvkms_per_open *)p0;
    for (;;) {
        IOLockLock(gKmsLock);
        bool run = !popen->closing;
        popen->eventWanted = false;
        struct NvKmsKapiDevice *device = popen->device;
        IOLockUnlock(gKmsLock);
        if (run) nvKmsKapiHandleEventQueueChange(device);
        IOLockLock(gKmsLock);
        if (!popen->closing && popen->eventWanted) {
            IOLockUnlock(gKmsLock);
            continue;
        }
        popen->eventBusy = false;
        IOLockWakeup(gKmsLock, popen, true);
        IOLockUnlock(gKmsLock);
        return;
    }
}

void nvkms_xnu_suspend_abort(uint32_t seq)
{
    if (!gKmsLock) return;
    IOLockLock(gKmsLock);
    if (gKmsSuspendPending && gKmsSuspendSeq == seq) {
        gKmsSuspendPending = false;
        gKmsSuspendSeq++;
        IOLockWakeup(gKmsLock, &gKmsPmPins, false);
        kms_close_retry_schedule_locked();
    }
    IOLockUnlock(gKmsLock);
}

void nvkms_xnu_resume(NvU32 gpuId, NvBool gpuOk)
{
    if (!gKmsLoaded) return;
    IOLockLock(gKmsLock);
    gKmsCloseRetryReady = false; // gpuResume has not opened the RM gate yet.
    // Cancel a request that has not committed yet, and wake its waiter so it returns instead of sleeping out
    // its bound. A committed suspend is unaffected: it already cleared the flag under this lock.
    gKmsSuspendPending = false;
    gKmsSuspendSeq++;
    IOLockWakeup(gKmsLock, &gKmsPmPins, false);
    if (gpuOk && gKmsPmState == kKmsPmSuspended) nvKmsResume(gpuId);
    gKmsPmState = gpuOk ? kKmsPmRunning : kKmsPmLost;
    IOLockWakeup(gKmsLock, &gKmsPmState, false);
    // Reclamation is scheduled by nvkms_xnu_reap_closes(), after the RM gate opens.
    // Do not wait for event callbacks on the PM owner thread: they may be blocked at that gate.
    IOLockUnlock(gKmsLock);
    if (gpuOk) nvKmsKapiSuspendResume(NV_FALSE);
    kprintf("NVRM-xnu: NVKMS %s (gpu 0x%x)\n", gpuOk ? "resumed" : "left LOST: the GPU did not resume", gpuId);
}

void nvkms_xnu_reap_closes(void)
{
    if (!gKmsLoaded) return;
    IOLockLock(gKmsLock);
    gKmsCloseRetryReady = (gKmsPmState == kKmsPmRunning);
    kms_close_retry_schedule_locked();
    IOLockUnlock(gKmsLock);
}

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
            gKmsCloseWorker = nullptr; node.eventBusy = true; kms_close_common(&node);
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
