// SPDX-License-Identifier: MIT
// HONOR G1 reconstruction candidate; never installed or loaded by this project.
#include <IOKit/IOLib.h>
#include <mach/semaphore.h>
#include <mach/sync_policy.h>
#include <kern/task.h>
#include <sys/systm.h>
#include "nvlink_os.h"

namespace {
struct NvlinkDarwinLock {
    semaphore_t semaphore;
};

[[noreturn]] void lockFailure(const char *operation, kern_return_t status)
{
    // The upstream void API cannot propagate failure. Never return without
    // acquiring the permit, or pretend that a failed signal/destroy succeeded.
    panic("HONOR G1 NVLink lock invariant: %s failed (%d)", operation, status);
}

NvlinkDarwinLock *checkedLock(void *handle)
{
    if (handle == nullptr)
        lockFailure("null handle", KERN_INVALID_ARGUMENT);
    return static_cast<NvlinkDarwinLock *>(handle);
}
} // namespace

extern "C" void *nvlink_allocLock(void)
{
    auto *lock = static_cast<NvlinkDarwinLock *>(IOMalloc(sizeof(NvlinkDarwinLock)));
    if (lock == nullptr)
        return nullptr;
    lock->semaphore = SEMAPHORE_NULL;
    kern_return_t status = semaphore_create(kernel_task, &lock->semaphore, SYNC_POLICY_FIFO, 1);
    if (status != KERN_SUCCESS) {
        IOFree(lock, sizeof(NvlinkDarwinLock));
        return nullptr;
    }
    return lock;
}

extern "C" void nvlink_acquireLock(void *handle)
{
    auto *lock = checkedLock(handle);
    kern_return_t status;
    do {
        status = semaphore_wait(lock->semaphore);
    } while (status == KERN_ABORTED);
    if (status != KERN_SUCCESS)
        lockFailure("wait", status);
}

extern "C" void nvlink_releaseLock(void *handle)
{
    auto *lock = checkedLock(handle);
    kern_return_t status = semaphore_signal(lock->semaphore);
    if (status != KERN_SUCCESS)
        lockFailure("signal", status);
}

extern "C" void nvlink_freeLock(void *handle)
{
    if (handle == nullptr)
        return;
    // Caller MUST exclude holders, waiters and future calls before destruction.
    // This primitive is not a lifetime manager and makes no concurrent-free claim.
    auto *lock = checkedLock(handle);
    kern_return_t status = semaphore_destroy(kernel_task, lock->semaphore);
    if (status != KERN_SUCCESS)
        lockFailure("destroy", status);
    IOFree(lock, sizeof(NvlinkDarwinLock));
}
