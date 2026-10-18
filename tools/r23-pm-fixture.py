#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the R23 PM-exclusion host test from the real functions in the tree.

Nothing is hand-copied: the state block and the five functions are extracted verbatim from the file
given on the command line (the candidate tree for the pass run, a git-archive snapshot of R22 for the
baseline run). The harness supplies IOLock/clock/kprintf stubs over pthreads and drives real threads
through the interleavings.
"""
import re
import sys
from pathlib import Path

NAMES = ["nvkms_xnu_suspend", "nvkms_xnu_resume", "nvkms_xnu_pm_pin", "nvkms_xnu_pm_unpin",
         "nvkms_xnu_pm_suspend_pending"]


def extract_fn(text, name):
    m = re.search(r"^[A-Za-z_][\w \*]*\b" + re.escape(name) + r"\s*\(", text, re.M)
    if not m:
        return None
    start = text.rfind("\n", 0, m.start()) + 1
    brace = text.index("{", m.end())
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return None


def extract_state(text):
    start = text.index("enum { kKmsPmRunning")
    end = text.index("kKmsPmName[]", start)
    end = text.index(";", end) + 1
    return text[start:end]


HARNESS = r"""
#include <cstdio>
#include <cstdarg>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <ctime>
#include <pthread.h>
#include <unistd.h>
#include <errno.h>

typedef int NvBool; typedef unsigned int NvU32;
#define NV_TRUE 1
#define NV_FALSE 0
#define THREAD_UNINT 0
#define THREAD_TIMED_OUT 1
typedef struct IOLock { pthread_mutex_t m; pthread_cond_t c; } IOLock;
static void kprintf(const char *fmt, ...) { va_list ap; va_start(ap, fmt); fputs("[kprintf] ", stderr); vfprintf(stderr, fmt, ap); va_end(ap); }

static std::uint64_t now_ms() { timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts); return (std::uint64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000; }
#define kMillisecondScale 1000
static void clock_interval_to_deadline(std::uint32_t ms, int, std::uint64_t *d) { *d = now_ms() + ms; }
static void IOLockLock(IOLock *l) { pthread_mutex_lock(&l->m); }
static void IOLockUnlock(IOLock *l) { pthread_mutex_unlock(&l->m); }
static void IOLockWakeup(IOLock *l, void *, bool) { pthread_cond_broadcast(&l->c); }
static int IOLockSleepDeadline(IOLock *l, void *, std::uint64_t dl, int) {
    std::uint64_t left = dl > now_ms() ? dl - now_ms() : 0;
    timespec ts; clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += left / 1000; ts.tv_nsec += (long)(left % 1000) * 1000000L;
    if (ts.tv_nsec >= 1000000000L) { ts.tv_sec++; ts.tv_nsec -= 1000000000L; }
    int rc = pthread_cond_timedwait(&l->c, &l->m, &ts);
    return rc == ETIMEDOUT ? THREAD_TIMED_OUT : 0;
}

// instrumented NVKMS entry points
static int gKmsSuspendCalls, gKmsResumeCalls, gKmsKapiTrue, gKmsKapiFalse;
static void nvKmsSuspend(NvU32) { __sync_fetch_and_add(&gKmsSuspendCalls, 1); }
static void nvKmsResume(NvU32) { __sync_fetch_and_add(&gKmsResumeCalls, 1); }
static void nvKmsKapiSuspendResume(NvBool on) { if (on) __sync_fetch_and_add(&gKmsKapiTrue, 1); else __sync_fetch_and_add(&gKmsKapiFalse, 1); }

static bool gKmsLoaded = true;
"""


def main():
    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    text = src.read_text(encoding="utf-8")

    old_sig = re.search(r"^void nvkms_xnu_suspend\s*\(\s*NvU32\s+gpuId\s*\)", text, re.M) is not None
    parts = [HARNESS]
    parts.append("// ---- extracted verbatim from %s ----\n" % src.as_posix())
    parts.append(extract_state(text) + "\n")
    parts.append("static IOLock gLockStorage;\nstatic IOLock *gKmsLock = &gLockStorage;\n")
    for name in NAMES:
        fn = extract_fn(text, name)
        if fn is None:
            continue
        parts.append(fn + "\n")

    if old_sig:
        parts.append("""
// R22 signature has no result: adapt it so the same scenarios can run against it. The baseline is
// expected to FAIL the pin scenarios, because R22 suspends anyway after the bounded wait.
static bool nvkms_xnu_suspend_bool(NvU32 gpuId, std::uint32_t) { nvkms_xnu_suspend(gpuId); return true; }
""")
        adapter = "nvkms_xnu_suspend_bool"
    else:
        adapter = "nvkms_xnu_suspend"

    parts.append(TESTS.replace("SUSPEND_CALL", adapter))
    out.write_text("".join(parts), encoding="utf-8", newline="\n")


TESTS = r"""
// ---------------------------------------------------------------------------
static int failures, checks;
static void check(const char *what, bool ok) { checks++; if (!ok) { failures++; std::printf("FAIL %s\n", what); } else std::printf("ok   %s\n", what); }

static void reset() {
    gKmsPmState = kKmsPmRunning; gKmsPmPins = 0;
#ifdef R23_HAS_PENDING
    gKmsSuspendPending = false; gKmsSuspendSeq = 0;
#endif
    gKmsSuspendCalls = gKmsResumeCalls = gKmsKapiTrue = gKmsKapiFalse = 0;
}

struct SuspendArg { std::uint32_t waitMs; bool result; };
static void *suspend_thread(void *p) { SuspendArg *a = (SuspendArg *)p; a->result = SUSPEND_CALL(1, a->waitMs); return nullptr; }

static void *unpin_later(void *p) { std::uint32_t ms = (std::uint32_t)(std::uintptr_t)p; usleep(ms * 1000); nvkms_xnu_pm_unpin(); return nullptr; }

int main() {
    pthread_mutex_init(&gLockStorage.m, nullptr); pthread_cond_init(&gLockStorage.c, nullptr);

    // 1. no pins: suspend goes through immediately, exactly one NVKMS suspend
    { reset(); bool r = SUSPEND_CALL(1, 5000);
      check("no pins -> suspend succeeds", r);
      check("no pins -> nvKmsSuspend called once", gKmsSuspendCalls == 1);
      check("no pins -> state suspended", gKmsPmState == kKmsPmSuspended); }

    // 2. a pin held: the bounded wait must give up without touching NVKMS (this is where R22 fails)
    { reset(); check("pin taken", nvkms_xnu_pm_pin() == NV_TRUE);
      std::uint64_t t0 = now_ms(); bool r = SUSPEND_CALL(1, 150); std::uint64_t dt = now_ms() - t0;
      check("held pin -> suspend refuses", r == false);
      check("held pin -> nvKmsSuspend never called", gKmsSuspendCalls == 0);
      check("held pin -> state still running", gKmsPmState == kKmsPmRunning);
      check("held pin -> wait was bounded", dt < 3000);
      check("held pin -> admission reopened", nvkms_xnu_pm_pin() == NV_TRUE);
      nvkms_xnu_pm_unpin(); }

    // 3. while a suspend is pending, new pins are refused
    { reset(); nvkms_xnu_pm_pin();
      SuspendArg a{3000, false}; pthread_t th; pthread_create(&th, nullptr, suspend_thread, &a);
      usleep(100 * 1000);
#ifdef R23_HAS_PENDING
      check("pending suspend refuses a new pin", nvkms_xnu_pm_pin() == NV_FALSE);
#endif
      nvkms_xnu_pm_unpin(); pthread_join(th, nullptr);
      check("last unpin lets the suspend proceed", a.result == true);
      check("last unpin -> exactly one nvKmsSuspend", gKmsSuspendCalls == 1); }

    // 4. duplicate request while one is pending is refused, the first still completes once
    { reset(); nvkms_xnu_pm_pin();
      SuspendArg a{3000, false}; pthread_t th; pthread_create(&th, nullptr, suspend_thread, &a);
      usleep(80 * 1000);
      bool dup = SUSPEND_CALL(1, 100);
      nvkms_xnu_pm_unpin(); pthread_join(th, nullptr);
      check("duplicate suspend is refused", dup == false);
      check("first suspend still completes once", a.result == true && gKmsSuspendCalls == 1); }

    // 5. resume cancels a pending suspend: no NVKMS suspend at all
    { reset(); nvkms_xnu_pm_pin();
      SuspendArg a{3000, true}; pthread_t th; pthread_create(&th, nullptr, suspend_thread, &a);
      usleep(80 * 1000);
      nvkms_xnu_resume(1, NV_TRUE);
      nvkms_xnu_pm_unpin(); pthread_join(th, nullptr);
      check("resume cancels the pending suspend", a.result == false);
      check("cancelled suspend never reached NVKMS", gKmsSuspendCalls == 0); }

    // 6. LOST is refused outright
    { reset(); gKmsPmState = kKmsPmLost;
      check("LOST -> suspend refused", SUSPEND_CALL(1, 100) == false);
      check("LOST -> no NVKMS suspend", gKmsSuspendCalls == 0); }

    // 7. a late unpin after an abandoned request must not trigger a second suspend
    { reset(); nvkms_xnu_pm_pin();
      bool r = SUSPEND_CALL(1, 120);
      check("abandoned request returns false", r == false);
      nvkms_xnu_pm_unpin(); usleep(50 * 1000);
      check("late unpin does not suspend", gKmsSuspendCalls == 0); }

    // 8. unpin from another thread during the wait completes the suspend exactly once
    { reset(); nvkms_xnu_pm_pin();
      SuspendArg a{3000, false}; pthread_t th; pthread_create(&th, nullptr, suspend_thread, &a);
      pthread_t up; pthread_create(&up, nullptr, unpin_later, (void *)(std::uintptr_t)100);
      pthread_join(up, nullptr); pthread_join(th, nullptr);
      check("async unpin releases the suspend", a.result == true);
      check("async unpin -> one suspend", gKmsSuspendCalls == 1);
      check("async unpin -> committed state", gKmsPmState == kKmsPmSuspended); }

    std::printf("RESULT: %d/%d checks%s\n", checks - failures, checks, failures ? " - FAIL" : "");
    return failures ? 1 : 0;
}
"""


if __name__ == "__main__":
    main()
