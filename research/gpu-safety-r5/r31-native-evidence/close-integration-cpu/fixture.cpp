
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

struct nvkms_per_open {
    void *data;
    enum NvKmsClientType type;
    struct NvKmsKapiDevice *device;
    thread_call_t eventCall;
    bool eventBusy, eventWanted, closing;
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

static void kms_close_common(struct nvkms_per_open *popen)
{
    if (!popen) return;
    IOLockLock(gKmsLock);
    // nvidia-modeset-os-interface.h: NVKMS keeps the pointer handed to nvKmsOpen() as pOpenKernel and
    // still passes it back to nvkms_event_queue_changed() until nvKmsClose() has destroyed that
    // per-open. While the GPU is suspended or lost nvKmsClose() must not touch the display engine
    // (a push to a core channel nobody serves spins in nvEvoMakeRoom), so a failed wait is not a
    // completed close: keep the per-open, this wrapper and its event worker allocated, refuse new
    // work, and never hand back memory NVKMS still points at.
    if (!kms_pm_wait_locked(false, kKmsPmWaitMs)) {
        popen->closing = true;
        popen->eventWanted = false;
        // Remember the node so a later resume can finish the close. A full table is reported, not hidden:
        // the per-open stays alive either way, and the counter below shows the backlog.
        if (kms_deferred_push(popen, popen->data) != 0) {
            kprintf("NVRM-xnu: deferred-close table is full; wrapper kept and tracked by the counter only\n");
        }
        gKmsCloseDeferred++;
        if (gKmsPmState == kKmsPmLost) gKmsCloseDeferredLost++;
        IOLockUnlock(gKmsLock);
        kprintf("NVRM-xnu: NVKMS close deferred while the GPU is %s: per-open and wrapper kept (deferred #%u, lost #%u)\n",
                kKmsPmName[gKmsPmState], (unsigned)gKmsCloseDeferred, (unsigned)gKmsCloseDeferredLost);
        return;
    }
    if (popen->data) nvKmsClose(popen->data);
    popen->data = NULL;
    popen->closing = true;
    if (popen->eventCall && popen->eventBusy) {
        if (thread_call_cancel(popen->eventCall)) popen->eventBusy = false;
        while (popen->eventBusy) IOLockSleep(gKmsLock, popen, THREAD_UNINT);
    }
    IOLockUnlock(gKmsLock);
    if (popen->eventCall && !thread_call_free(popen->eventCall)) {
        // A pending or rearmed call makes thread_call_free fail. Keep the
        // argument alive; successful release is not a callback join operation.
        kprintf("NVRM-xnu: NVKMS close could not free its event call; closing wrapper retained\n");
        return;
    }
    nvkms_free(popen, sizeof *popen);
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
        while (popen->eventBusy) IOLockSleep(gKmsLock, popen, THREAD_UNINT);
    }
    if (popen->eventCall && !thread_call_free(popen->eventCall)) {
        // A pending or rearmed call keeps the argument alive; leave it queued for the next resume.
        return 0;
    }
    popen->eventCall = NULL;
    popen->data = NULL;
    if (gKmsCloseDeferred) gKmsCloseDeferred--;
    nvkms_free(popen, sizeof *popen);
    return 1;
}

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
