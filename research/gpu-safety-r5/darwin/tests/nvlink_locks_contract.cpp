// SPDX-License-Identifier: MIT
// Same production TU, mocked Darwin services. CPU contracts only.
#include "semaphore_fixture.h"
#include "nvlink_os.h"
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <mutex>
#include <thread>
#include <vector>

struct TestSemaphore {
    std::mutex lock;
    std::condition_variable cv;
    int count;
    int waiters = 0;
    explicit TestSemaphore(int initial) : count(initial) {}
};
void *kernel_task = reinterpret_cast<void *>(1);
static bool failAlloc = false, failCreate = false;
static thread_local int abortWaits = 0, failWait = 0, failSignal = 0, failDestroy = 0;
static std::atomic<int> allocations{0}, semaphores{0}, waits{0};
struct Fatal {};
[[noreturn]] void panic(const char *, ...) { throw Fatal{}; }
void *IOMalloc(std::size_t bytes) {
    if (failAlloc) return nullptr;
    void *p = std::malloc(bytes);
    if (p) ++allocations;
    return p;
}
void IOFree(void *p, std::size_t) { --allocations; std::free(p); }
kern_return_t semaphore_create(void *task, semaphore_t *out, int policy, int count) {
    *out = nullptr;
    if (task != kernel_task || policy != SYNC_POLICY_FIFO || count != 1) std::abort();
    if (failCreate) return KERN_FAILURE;
    *out = new TestSemaphore(count);
    ++semaphores;
    return KERN_SUCCESS;
}
kern_return_t semaphore_wait(semaphore_t s) {
    ++waits;
    if (abortWaits) { --abortWaits; return KERN_ABORTED; }
    if (failWait) return failWait;
    std::unique_lock<std::mutex> guard(s->lock);
    ++s->waiters;
    s->cv.notify_all();
    s->cv.wait(guard, [s] { return s->count > 0; });
    --s->waiters;
    --s->count;
    return KERN_SUCCESS;
}
kern_return_t semaphore_signal(semaphore_t s) {
    if (failSignal) return failSignal;
    std::lock_guard<std::mutex> guard(s->lock);
    ++s->count;
    s->cv.notify_one();
    return KERN_SUCCESS;
}
kern_return_t semaphore_destroy(void *task, semaphore_t s) {
    if (task != kernel_task) std::abort();
    if (failDestroy) return failDestroy;
    // All test free calls obey the documented caller-quiescence precondition.
    if (s->waiters) std::abort();
    delete s;
    --semaphores;
    return KERN_SUCCESS;
}

static int passed = 0, failed = 0;
static void check(bool ok, const char *name) {
    std::printf("%s %s\n", ok ? "PASS" : "FAIL", name);
    if (ok) ++passed; else ++failed;
}
static bool fatal(const std::function<void()> &call) {
    try { call(); return false; } catch (const Fatal &) { return true; }
}
// Inspection is test-only. The candidate stores exactly one semaphore_t.
static TestSemaphore *sema(void *p) { return *static_cast<semaphore_t *>(p); }
static bool blocked(void *p) {
    auto *s = sema(p);
    std::unique_lock<std::mutex> guard(s->lock);
    return s->cv.wait_for(guard, std::chrono::seconds(2), [s] { return s->waiters > 0; });
}
int main() {
    failAlloc = true;
    check(nvlink_allocLock() == nullptr && allocations == 0 && semaphores == 0, "allocation failure returns null without resources");
    failAlloc = false;
    failCreate = true;
    check(nvlink_allocLock() == nullptr && allocations == 0 && semaphores == 0, "create failure frees wrapper");
    failCreate = false;
    void *p = nvlink_allocLock();
    check(p != nullptr && allocations == 1 && semaphores == 1, "create one real permit");
    nvlink_acquireLock(p);
    check(sema(p)->count == 0, "initial permit acquired");

    std::atomic<bool> entered{false};
    std::thread waiter([&] { nvlink_acquireLock(p); entered = true; nvlink_releaseLock(p); });
    bool didBlock = blocked(p);
    check(didBlock && !entered, "contender blocks before release");
    // A different thread releases a permit taken by main: semaphore, not mutex.
    std::thread signaller([&] { nvlink_releaseLock(p); });
    signaller.join();
    waiter.join();
    check(entered && sema(p)->count == 1, "cross-thread signal wakes waiter and preserves permit");

    std::atomic<int> total{0};
    std::atomic<int> active{0}, overlaps{0};
    std::vector<std::thread> threads;
    for (int t = 0; t < 6; ++t) threads.emplace_back([&] {
        for (int i = 0; i < 2000; ++i) {
            nvlink_acquireLock(p);
            if (active.fetch_add(1) != 0) ++overlaps;
            ++total;
            active.fetch_sub(1);
            nvlink_releaseLock(p);
        }
    });
    for (auto &t : threads) t.join();
    check(total == 12000 && overlaps == 0 && sema(p)->count == 1, "12000 contended critical sections exclude peers");

    int before = waits;
    abortWaits = 2;
    nvlink_acquireLock(p);
    check(waits == before + 3 && sema(p)->count == 0, "aborted waits retried until permit actually acquired");
    nvlink_releaseLock(p);
    for (int error : {KERN_TERMINATED, KERN_INVALID_ARGUMENT, KERN_FAILURE}) {
        failWait = error;
        check(fatal([&] { nvlink_acquireLock(p); }) && sema(p)->count == 1, "unrecoverable wait never returns to caller");
    }
    failWait = 0;
    nvlink_acquireLock(p);
    failSignal = KERN_TERMINATED;
    check(fatal([&] { nvlink_releaseLock(p); }) && sema(p)->count == 0, "failed signal never reports success");
    failSignal = 0;
    nvlink_releaseLock(p);
    failDestroy = KERN_INVALID_ARGUMENT;
    check(fatal([&] { nvlink_freeLock(p); }) && allocations == 1 && semaphores == 1, "failed destroy does not free live wrapper");
    failDestroy = 0;
    nvlink_freeLock(p);
    check(allocations == 0 && semaphores == 0, "quiescent destroy frees semaphore and wrapper once");
    check(fatal([] { nvlink_acquireLock(nullptr); }), "null acquire cannot succeed");
    check(fatal([] { nvlink_releaseLock(nullptr); }), "null release cannot succeed");
    nvlink_freeLock(nullptr);
    check(allocations == 0 && semaphores == 0, "null free matches upstream no-op");
    std::printf("RESULT passed=%d failed=%d CPU_CONTRACT_ONLY\n", passed, failed);
    return failed ? 1 : 0;
}
