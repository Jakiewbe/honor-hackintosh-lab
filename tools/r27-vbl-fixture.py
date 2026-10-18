#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R27: deterministic interleaving test for the VBL reference (audit item B).

Extracts armVbl(), vblFire() and the whole stop() body verbatim from intelfb.cpp and drives them with an
emulated thread_call whose "running" flag the test controls, so every interleaving is deterministic.
"""
import re
import sys
from pathlib import Path


def brace_block(text, start_idx):
    b = text.index("{", start_idx)
    depth = 0
    for i in range(b, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start_idx:i + 1]
    raise ValueError("unbalanced")


def extract(text, anchor_regex):
    m = re.search(anchor_regex, text, re.M)
    if not m:
        return None
    start = text.rfind("\n", 0, m.start()) + 1
    return brace_block(text, start)


PRELUDE = r"""
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <cstdarg>
typedef int IOReturn; typedef unsigned int NvU32;
typedef unsigned long long mach_time_t;
typedef void *thread_call_param_t;
struct IOService;
static int gRetain, gRelease;
static void IFBLOG(const char *fmt, ...) { (void)fmt; }
struct IOLock; 
struct IOFramebuffer { void stop(void *) {} };
struct thread_call;
typedef thread_call *thread_call_t;
struct thread_call {
    void (*fn)(void *, void *);
    void *arg;
    bool pending, running, freed;
};
static thread_call_t gAllocResult = (thread_call_t)1;   // set to nullptr to force an allocation failure
static thread_call *thread_call_allocate(void (*fn)(void *, void *), void *arg) {
    if (!gAllocResult) return nullptr;
    thread_call *t = new thread_call();
    t->fn = fn; t->arg = arg; t->pending = false; t->running = false; t->freed = false;
    return t;
}
static bool thread_call_enter_delayed(thread_call *t, mach_time_t) { if (!t) return false; t->pending = true; return true; }
static bool thread_call_cancel(thread_call *t) { if (!t) return false; bool was = t->pending; t->pending = false; return was; }
static bool thread_call_free(thread_call *t) { if (!t) return false; if (t->running || t->pending) return false; t->freed = true; return true; }
static mach_time_t fNow = 1000;
#define mach_absolute_time() (fNow)
static void nanoseconds_to_absolutetime(uint64_t ns, uint64_t *out) { *out = ns; }
static void clock_interval_to_deadline(uint32_t, int, uint64_t *d) { *d = fNow + 1; }
#define kMicrosecondScale 1000
static void IOSleep(unsigned) {}
static void OSSafeReleaseNULL(void *&p) { p = nullptr; }
struct IOLock { };
static void IOLockLock(IOLock *) {}
static void IOLockUnlock(IOLock *) {}
static void IOLockFree(IOLock *) {}
struct NMIntelFB;

struct NMIntelFB : IOFramebuffer {
    int refs = 1;
    void retain() { ++refs; ++gRetain; }
    void release() { --refs; ++gRelease; }
    typedef void (*IOFBInterruptProc)(void *target, void *ref);
    struct Irq { IOFBInterruptProc proc = nullptr; void *target = nullptr; void *ref = nullptr; };
    Irq fVbl, fConnect;
    thread_call_t fVblTimer = nullptr;
    bool fVblRefOwned = false;
    uint64_t fVblNext = 0, fVblCalls = 0;
    volatile bool fStopping = false;
    uint32_t fFrameNs = 16666667;
    IOLock *fCopyLock = nullptr;
    void *fSurfMap = nullptr, *fMMIO = nullptr;
    void *fRegs = nullptr;
"""

EPILOGUE = r"""
};

static int failures, checks;
static void check(const char *what, bool ok) { checks++; if (!ok) { failures++; std::printf("FAIL %s\n", what); } else std::printf("ok   %s\n", what); }
static void reset() { gRetain = gRelease = 0; gAllocResult = (thread_call_t)1; }

int main() {
    // 1. arm succeeds -> one retain; a successful stop returns it exactly once
    { reset(); NMIntelFB fb; fb.armVbl();
      check("armVbl takes exactly one reference", gRetain == 1 && fb.refs == 2);
      thread_call_t t = fb.fVblTimer; t->pending = false;
      fb.stop(nullptr);
      check("stop returns the reference once", gRelease == 1 && fb.refs == 1);
      check("a later callback cannot release again", fb.fVblRefOwned == false);
      fb.fStopping = true; t->running = true; fb.vblFire(&fb, nullptr);
      check("late callback does not double release", gRelease == 1); }

    // 2. allocation failure takes no reference
    { reset(); gAllocResult = nullptr; NMIntelFB fb; fb.armVbl();
      check("failed allocate takes no reference", gRetain == 0 && fb.fVblRefOwned == false);
      fb.fVblTimer = nullptr; fb.stop(nullptr);
      check("stop after a failed allocate releases nothing", gRelease == 0); }

    // 3. callback in flight: stop keeps the reference, the callback returns it (exactly once)
    { reset(); NMIntelFB fb; fb.armVbl();
      thread_call_t t = fb.fVblTimer; t->running = true; t->pending = false;
      fb.stop(nullptr);
      check("stop keeps the reference when the call is in flight", gRelease == 0 && fb.fVblRefOwned);
      fb.vblFire(&fb, nullptr);
      check("the callback returns it once", gRelease == 1 && fb.refs == 1);
      fb.vblFire(&fb, nullptr);
      check("a second callback entry releases nothing", gRelease == 1); }

    // 4. stop twice does not release twice
    { reset(); NMIntelFB fb; fb.armVbl(); thread_call_t t = fb.fVblTimer; t->pending = false;
      fb.stop(nullptr); fb.stop(nullptr);
      check("double stop releases once", gRelease == 1); }

    // 5. arming twice does not take a second reference
    { reset(); NMIntelFB fb; fb.armVbl(); thread_call_t first = fb.fVblTimer; fb.armVbl();
      check("re-arm keeps one reference", gRetain == 1 && fb.fVblTimer == first); }

    std::printf("RESULT: %d/%d checks%s\n", checks - failures, checks, failures ? " - FAIL" : "");
    return failures ? 1 : 0;
}
"""


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    text = src.read_text(encoding="utf-8")
    arm = extract(text, r"void armVbl\(\)")
    vbl = extract(text, r"static void vblFire\(thread_call_param_t p0, thread_call_param_t\)")
    stop = extract(text, r"void NMIntelFB::stop\(IOService \*provider\)")
    if not (arm and vbl and stop):
        raise SystemExit("could not extract the three functions")
    stop = stop.replace("void NMIntelFB::stop(IOService *provider)", "void stop(IOService *provider)")
    body = PRELUDE + arm + "\n" + vbl + "\n" + stop + "\n" + EPILOGUE
    out.write_text(body, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
