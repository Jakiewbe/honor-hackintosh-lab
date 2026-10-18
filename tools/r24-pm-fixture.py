import hashlib
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R24 PM-exclusion host test generator (begin / commit / abort).

Extracts the state block and the six functions verbatim from the file given on the command line. For the
R22 baseline (a single void nvkms_xnu_suspend) it synthesises adapters so the same scenarios run; the
baseline is expected to fail the "a held pin must block the suspend" checks.
"""
import re
import sys
from pathlib import Path

NEW_NAMES = ["nvkms_xnu_suspend_begin", "nvkms_xnu_suspend_commit", "nvkms_xnu_suspend_abort",
             "nvkms_xnu_resume", "nvkms_xnu_pm_pin", "nvkms_xnu_pm_unpin", "nvkms_xnu_pm_suspend_pending"]


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
    return text[start:text.index(";", end) + 1]


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
static void kprintf(const char *fmt, ...) { va_list ap; va_start(ap, fmt); vfprintf(stderr, fmt, ap); va_end(ap); }
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
    return pthread_cond_timedwait(&l->c, &l->m, &ts) == ETIMEDOUT ? THREAD_TIMED_OUT : 0;
}
static int gKmsSuspendCalls, gKmsResumeCalls, gKmsKapiTrue, gKmsKapiFalse;
static void nvKmsSuspend(NvU32) { __sync_fetch_and_add(&gKmsSuspendCalls, 1); }
static void nvKmsResume(NvU32) { __sync_fetch_and_add(&gKmsResumeCalls, 1); }
static void nvKmsKapiSuspendResume(NvBool on) { if (on) __sync_fetch_and_add(&gKmsKapiTrue, 1); else __sync_fetch_and_add(&gKmsKapiFalse, 1); }
static bool gKmsLoaded = true;
"""


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    text = src.read_text(encoding="utf-8")
    old_api = extract_fn(text, "nvkms_xnu_suspend_begin") is None

    parts = [HARNESS, "// ---- extracted from %s ----\n" % src.as_posix(), extract_state(text) + "\n",
             "static IOLock gLockStorage;\nstatic IOLock *gKmsLock = &gLockStorage;\n"]
    for name in NEW_NAMES:
        fn = extract_fn(text, name)
        if fn:
            parts.append(fn + "\n")

    if old_api:
        parts.append("""
// R22 baseline adapters: its nvkms_xnu_suspend() suspends immediately regardless of pins.
static void nvkms_xnu_suspend(NvU32 gpuId);
static NvBool nvkms_xnu_suspend_begin(std::uint32_t *seq) { nvkms_xnu_suspend(1); if (seq) *seq = 1; return NV_TRUE; }
static NvBool nvkms_xnu_suspend_commit(NvU32, std::uint32_t, std::uint32_t) { return NV_TRUE; }
static void   nvkms_xnu_suspend_abort(std::uint32_t) {}
""")
        # only the old suspend itself; pin/unpin/resume already came from the NEW_NAMES loop
        fn = extract_fn(text, "nvkms_xnu_suspend")
        if fn:
            parts.append(fn + "\n")

    parts.append(TESTS)
    out.write_text(_provenance(src) + "".join(parts), encoding="utf-8", newline="\n")


TESTS = r"""
static int failures, checks;
static void check(const char *what, bool ok) { checks++; if (!ok) { failures++; std::printf("FAIL %s\n", what); } else std::printf("ok   %s\n", what); }
static void reset() {
    gKmsPmState = kKmsPmRunning; gKmsPmPins = 0;
#ifdef R24_HAS_PENDING
    gKmsSuspendPending = false; gKmsSuspendSeq = 0;
#endif
    gKmsSuspendCalls = gKmsResumeCalls = gKmsKapiTrue = gKmsKapiFalse = 0;
}
struct CommitArg { std::uint32_t seq, waitMs; bool result; };
static void *commit_thread(void *p) { CommitArg *a = (CommitArg *)p; a->result = nvkms_xnu_suspend_commit(1, a->seq, a->waitMs); return nullptr; }
static void *unpin_later(void *p) { usleep((useconds_t)((std::uintptr_t)p) * 1000); nvkms_xnu_pm_unpin(); return nullptr; }

int main() {
    pthread_mutex_init(&gLockStorage.m, nullptr); pthread_cond_init(&gLockStorage.c, nullptr);
    std::uint32_t seq = 0;

    // 1. no pins: begin then commit suspends once
    { reset(); check("begin without pins", nvkms_xnu_suspend_begin(&seq) == NV_TRUE);
      check("commit without pins succeeds", nvkms_xnu_suspend_commit(1, seq, 5000) == NV_TRUE);
      check("commit suspends exactly once", gKmsSuspendCalls == 1);
      check("state is suspended", gKmsPmState == kKmsPmSuspended); }

    // 2. a pin held: admission closes, commit must NOT suspend (R22 fails here)
    { reset(); nvkms_xnu_pm_pin();
      check("begin with a pin held", nvkms_xnu_suspend_begin(&seq) == NV_TRUE);
      check("begin closes pin admission", nvkms_xnu_pm_pin() == NV_FALSE);
      std::uint64_t t0 = now_ms();
      check("commit refuses while the pin is held", nvkms_xnu_suspend_commit(1, seq, 150) == NV_FALSE);
      check("refused commit never touches NVKMS", gKmsSuspendCalls == 0);
      check("refused commit keeps NVKMS running", gKmsPmState == kKmsPmRunning);
      check("refused commit was bounded", now_ms() - t0 < 3000);
      nvkms_xnu_suspend_abort(seq);
      check("abort reopens admission", nvkms_xnu_pm_pin() == NV_TRUE);
      nvkms_xnu_pm_unpin(); }

    // 3. the last unpin lets a waiting commit through, exactly once
    { reset(); nvkms_xnu_pm_pin(); nvkms_xnu_suspend_begin(&seq);
      CommitArg a{seq, 3000, false}; pthread_t th; pthread_create(&th, nullptr, commit_thread, &a);
      pthread_t up; pthread_create(&up, nullptr, unpin_later, (void *)(std::uintptr_t)100);
      pthread_join(up, nullptr); pthread_join(th, nullptr);
      check("async unpin lets the commit succeed", a.result == true);
      check("async unpin suspends exactly once", gKmsSuspendCalls == 1);
      check("async unpin commits the state", gKmsPmState == kKmsPmSuspended); }

    // 4. duplicate begin is refused, the first request still completes once
    { reset(); nvkms_xnu_pm_pin(); nvkms_xnu_suspend_begin(&seq);
      std::uint32_t other = 0;
      check("duplicate begin refused", nvkms_xnu_suspend_begin(&other) == NV_FALSE);
      nvkms_xnu_pm_unpin();
      check("first request still commits", nvkms_xnu_suspend_commit(1, seq, 3000) == NV_TRUE && gKmsSuspendCalls == 1); }

    // 5. resume cancels a pending request: commit fails, no suspend
    { reset(); nvkms_xnu_pm_pin(); nvkms_xnu_suspend_begin(&seq);
      nvkms_xnu_resume(1, NV_TRUE);
      nvkms_xnu_pm_unpin();
      check("resume cancels the request", nvkms_xnu_suspend_commit(1, seq, 3000) == NV_FALSE);
      check("cancelled request never suspends", gKmsSuspendCalls == 0); }

    // 6. LOST is refused at begin
    { reset(); gKmsPmState = kKmsPmLost;
      check("LOST refuses begin", nvkms_xnu_suspend_begin(&seq) == NV_FALSE);
      check("LOST never suspends", gKmsSuspendCalls == 0); }

    // 7. abandoned request: a late unpin must not suspend, and a late commit is refused
    { reset(); nvkms_xnu_pm_pin(); nvkms_xnu_suspend_begin(&seq);
      check("commit gives up", nvkms_xnu_suspend_commit(1, seq, 120) == NV_FALSE);
      nvkms_xnu_suspend_abort(seq);
      nvkms_xnu_pm_unpin(); usleep(50 * 1000);
      check("late unpin does not suspend", gKmsSuspendCalls == 0);
      check("late commit is refused", nvkms_xnu_suspend_commit(1, seq, 100) == NV_FALSE); }

    // 8. a stale sequence number cannot commit someone else's request
    { reset(); nvkms_xnu_suspend_begin(&seq);
      check("stale sequence refused", nvkms_xnu_suspend_commit(1, seq + 99, 100) == NV_FALSE);
      check("stale sequence never suspends", gKmsSuspendCalls == 0);
      check("the live request still works", nvkms_xnu_suspend_commit(1, seq, 100) == NV_TRUE); }

    std::printf("RESULT: %d/%d checks%s\n", checks - failures, checks, failures ? " - FAIL" : "");
    return failures ? 1 : 0;
}
"""

def _provenance(path):
    """Fingerprint of the source the test was generated from, written into the test itself."""
    return "// source: %s\n// source_sha256: %s\n" % (
        path.as_posix(), hashlib.sha256(Path(path).read_bytes()).hexdigest())

if __name__ == "__main__":
    main()
