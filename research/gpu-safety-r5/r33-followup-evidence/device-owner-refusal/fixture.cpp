/*
 * SPDX-FileCopyrightText: Copyright (c) 2015-2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

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

struct nvkms_per_open;
struct NvKmsKapiEvent;
struct NvKmsKapiDevice {
    int semaphore, notifier, hKmsDevice, hKmsDisp, gpuId;
    void *pSema, *privateData;
    nvkms_per_open *pKmsOpen;
    void (*eventCallback)(NvKmsKapiEvent *);
};
struct NvKmsFreeDeviceParams { struct { int deviceHandle; } request; };
struct NvKmsGetNextEventParams {
    struct { bool valid; struct { int eventType; struct {
        struct { int dpyId; } dpyChanged, dynamicDpyConnected;
        struct { int head, layer; } flipOccurred;
    } u; } event; } reply;
};
struct NvKmsKapiEvent {
    int type; NvKmsKapiDevice *device; void *privateData;
    struct { struct { int display; } displayChanged, dynamicDisplayConnected;
             struct { int head, layer; } flipOccurred; } u;
};
enum { NVKMS_IOCTL_FREE_DEVICE, NVKMS_IOCTL_GET_NEXT_EVENT,
       NVKMS_EVENT_TYPE_DPY_CHANGED, NVKMS_EVENT_TYPE_DYNAMIC_DPY_CONNECTED,
       NVKMS_EVENT_TYPE_FLIP_OCCURRED };
static int device_frees, rm_frees, downstream_events;
static int nvkms_ioctl_from_kapi(nvkms_per_open *, int, void *, size_t);
static void nvkms_close_from_kapi(nvkms_per_open *);
static void nvKmsKapiFreeNisoSurface(NvKmsKapiDevice *, int *) {}
static void RmFreeDevice(NvKmsKapiDevice *) { ++rm_frees; }
static void nvkms_close_gpu(int, int) {}
static void nvkms_sema_free(void *) {}
static void nvKmsKapiFree(NvKmsKapiDevice *) { ++device_frees; } // Counts, no deletion.
static int nvDpyIdToNvU32(int x) { return x; }
static void nvKmsKapiLogDeviceDebug(NvKmsKapiDevice *, const char *) {}
static void nvAssert(bool ok) { if (!ok) throw std::runtime_error("OGKM assertion"); }

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
static int backend_closes, wrapper_frees, sleeps, deadline_sleeps, schedules, lock_depth;
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
void nvKmsKapiHandleEventQueueChange(NvKmsKapiDevice *);
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
    // KAPI FreeDevice continues releasing Device immediately after this void close returns.
    // Until Device ownership can also be deferred, keep the normal-close callback join.
    // This wait is still unbounded and is an explicit OPEN contract, not a safe async close.
    if (popen->eventCall && popen->eventBusy) {
        if (thread_call_cancel(popen->eventCall)) popen->eventBusy = false;
        while (popen->eventBusy) IOLockSleep(gKmsLock, popen, THREAD_UNINT);
    }
    // If its call cannot be released, the queue becomes the sole
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

static void KmsFreeDevice(struct NvKmsKapiDevice *device)
{
    /* Free notifier and semaphore memory */

    nvKmsKapiFreeNisoSurface(device, &device->semaphore);
    nvKmsKapiFreeNisoSurface(device, &device->notifier);

    /* Free NVKMS device */

    if (device->hKmsDevice != 0x0)  {
        struct NvKmsFreeDeviceParams paramsFree = { };

        paramsFree.request.deviceHandle = device->hKmsDevice;

        nvkms_ioctl_from_kapi(device->pKmsOpen,
                              NVKMS_IOCTL_FREE_DEVICE,
                              &paramsFree, sizeof(paramsFree));

        device->hKmsDevice = device->hKmsDisp = 0x0;
    }

    /* Close NVKMS */

    if (device->pKmsOpen != NULL) {
        nvkms_close_from_kapi(device->pKmsOpen);
        device->pKmsOpen = NULL;
    }
}

static void FreeDevice(struct NvKmsKapiDevice *device)
{
    /* AllocateDevice() also reaches this path when its first allocation fails. */
    if (device == NULL) {
        return;
    }

    /* Free NVKMS objects allocated for NvKmsKapiDevice */

    KmsFreeDevice(device);

    /* Free RM objects allocated for NvKmsKapiDevice */

    RmFreeDevice(device);

    /* Lower the reference count of gpu. */

    nvkms_close_gpu(device->gpuId, NV_TRUE /* reset_aware */);

    if (device->pSema != NULL) {
        nvkms_sema_free(device->pSema);
    }

    nvKmsKapiFree(device);
}

void nvKmsKapiHandleEventQueueChange
(
    struct NvKmsKapiDevice *device
)
{
    if (device == NULL) {
        return;
    }

    /*
     * If the callback is NULL, event interest declaration should be
     * rejected, and no events would be reported.
     */
    nvAssert(device->eventCallback != NULL);

    do
    {
        struct NvKmsGetNextEventParams kmsEventParams = { };
        struct NvKmsKapiEvent kapiEvent = { };
        NvBool err = NV_FALSE;

        if (!nvkms_ioctl_from_kapi(device->pKmsOpen,
                                   NVKMS_IOCTL_GET_NEXT_EVENT,
                                   &kmsEventParams, sizeof(kmsEventParams))) {
            break;
        }

        if (!kmsEventParams.reply.valid) {
            break;
        }

        kapiEvent.type = kmsEventParams.reply.event.eventType;

        kapiEvent.device = device;
        kapiEvent.privateData = device->privateData;

        switch (kmsEventParams.reply.event.eventType) {
            case NVKMS_EVENT_TYPE_DPY_CHANGED:
                kapiEvent.u.displayChanged.display =
                    nvDpyIdToNvU32(kmsEventParams.
                                   reply.event.u.dpyChanged.dpyId);
                break;
            case NVKMS_EVENT_TYPE_DYNAMIC_DPY_CONNECTED:
                kapiEvent.u.dynamicDisplayConnected.display =
                    nvDpyIdToNvU32(kmsEventParams.
                                   reply.event.u.dynamicDpyConnected.dpyId);
                break;
            case NVKMS_EVENT_TYPE_FLIP_OCCURRED:
                kapiEvent.u.flipOccurred.head =
                    kmsEventParams.reply.event.u.flipOccurred.head;
                kapiEvent.u.flipOccurred.layer =
                    kmsEventParams.reply.event.u.flipOccurred.layer;
                break;
            default:
                continue;
        }

        if (err) {
            nvKmsKapiLogDeviceDebug(
                device,
                "Error in conversion from "
                "NvKmsGetNextEventParams to NvKmsKapiEvent");
            continue;
        }

        device->eventCallback(&kapiEvent);

    } while(1);
}

static NvKmsKapiDevice device;
static nvkms_per_open node;
static bool refusal_mode, teardown_refused;
static void nvkms_close_from_kapi(nvkms_per_open *p) { kms_close_common(p); }
static int nvkms_ioctl_from_kapi(nvkms_per_open *, int cmd, void *params, size_t) {
    if (cmd == NVKMS_IOCTL_FREE_DEVICE) {
        if (refusal_mode) { teardown_refused = true; return 0; }
        return 1;
    }
    require(cmd == NVKMS_IOCTL_GET_NEXT_EVENT, "unexpected ioctl");
    // The event was already fetched. Teardown races before the handler consumes it.
    FreeDevice(&device);
    auto *event = static_cast<NvKmsGetNextEventParams *>(params);
    event->reply.valid = true;
    event->reply.event.eventType = NVKMS_EVENT_TYPE_DPY_CHANGED;
    return 1;
}
static void checked_event(NvKmsKapiEvent *) {
    ++downstream_events;
    require(device_frees == 0, "DEVICE_FREED_BEFORE_ACTIVE_EVENT_FINISHED");
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int data;
    gKmsCloseWorker = &worker_id;
    node.data = &data; node.eventCall = &data; node.eventBusy = true; node.device = &device;
    device.pKmsOpen = &node; device.eventCallback = checked_event;
    (void)kms_close_retry_fire;
    try {
        if (std::strcmp(argv[1], "backend-refused") == 0) {
            refusal_mode = true; gKmsPmState = kKmsPmLost;
            node.eventBusy = false; device.hKmsDevice = 1;
            FreeDevice(&device);
            require(!(teardown_refused && (rm_frees || device_frees)), "DEVICE_DESTROYED_AFTER_KMS_REFUSAL");
        } else {
            require(std::strcmp(argv[1], "active-event") == 0, "unknown scenario");
            kms_kapi_event_fire(&node, nullptr);
        }
        std::printf("UNEXPECTED_PASS\n");
        return 0;
    } catch (const std::exception &error) {
        std::printf("CONTRACT_FAIL %s backend_close=%d wrapper_free=%d queued=%u device_free=%d rm_free=%d events=%d sleeps=%d\n",
            error.what(), backend_closes, wrapper_frees, kms_deferred_count(), device_frees,
            rm_frees, downstream_events, sleeps);
        return 1;
    }
}
