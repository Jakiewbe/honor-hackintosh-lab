#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Host test for the R10/R11 device lifetime: both real functions, injected KAPI + PM boundaries.

Extracted verbatim: NVRMNVDAFramebuffer::dropKapiDevice() and ::finishOrphanedDevice().
Injected: the KAPI function table, gDev, gDevUsers, gDevOrphaned, gHeadsTaken, FBLOG and the
PM predicate. Nothing here models the functions; it drives them.
"""
import hashlib
import json
from pathlib import Path

W = Path(r"D:\Hactk\gpu-r5-20261017")
import os
SRC = Path(os.environ.get("R11_SRC", W / "src" / "kexts/NVRMFB/fb/nvrm-fb.cpp"))
OUT = W / "evidence" / "r11"
def provenance(path):
    h = hashlib.sha256(path.read_bytes()).hexdigest()
    return "// source: %s\n// source_sha256: %s\n" % (path.as_posix(), h)
OUT.mkdir(parents=True, exist_ok=True)


def body(text, marker):
    start = text.index(marker)
    brace = text.index("{", start)
    depth, i = 0, brace
    while True:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
        i += 1


SHIM = r"""
#include <cstdio>
#include <cstdint>
#include <cstdlib>

using NvU32 = uint32_t;
using NvBool = int;

struct NvKmsKapiDevice { int id; };
struct NvKmsKapiFunctionsTable {
    void (*releaseOwnership)(struct NvKmsKapiDevice *);
    void (*freeDevice)(struct NvKmsKapiDevice *);
};

static struct NvKmsKapiDevice *gDev;
static int gDevUsers;
static bool gDevOrphaned;
static int gOrphanGrabs;
struct NVRMNVDAFramebuffer;
static NVRMNVDAFramebuffer *gDevCreator;
static int creatorRefs, creatorReleases;
static NvU32 gHeadsTaken;
static int releases, frees, checks, failures;
static void onRelease(struct NvKmsKapiDevice *) { ++releases; }
static void onFree(struct NvKmsKapiDevice *) { ++frees; }
static bool gPmRunning = true;
extern "C" NvBool nvkms_xnu_pm_running(void) { return gPmRunning ? 1 : 0; }
static int pins, unpins;
static bool gFlipOnPin = false;
extern "C" NvBool nvkms_xnu_pm_pin(void) {
    if (!gPmRunning) return 0;
    ++pins;
    if (gFlipOnPin) { gPmRunning = false; gFlipOnPin = false; }   // a resume flips LOST right after the pin
    return 1; }
extern "C" void nvkms_xnu_pm_unpin(void) { ++unpins; }
static uint32_t deferredCloses, lostCloses;
extern "C" void nvkms_xnu_kms_close_deferred_count(uint32_t *t, uint32_t *l) {
    if (t) { *t = deferredCloses; }
    if (l) { *l = lostCloses; }
}
#define FBLOG(...) do { } while (0)

struct NVRMDisplayGate { bool valid() const { return true; } };

static void req(bool ok, const char *what)
{
    ++checks;
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", what); ++failures; }
}

struct NVRMNVDAFramebuffer {
    int refs = 1;
    void retain() { ++refs; ++creatorRefs; }
    void release() { --refs; ++creatorReleases; }
    struct NvKmsKapiFunctionsTable *fKms;
    struct NvKmsKapiDevice *fDev = nullptr;
    bool fGrabbedOwnership = false;
    bool fOwnsHead = false;
    NvU32 fHead = 0;
"""

MAIN = r"""
};

int main()
{
    NvKmsKapiFunctionsTable table = { onRelease, onFree };
    NvKmsKapiDevice devA { 1 };
    NvKmsKapiDevice devB { 2 };
    auto reset = [&] { releases = frees = 0; gDevUsers = 0; gDevOrphaned = false; gOrphanGrabs = 0; gDevCreator = nullptr; creatorRefs = creatorReleases = 0; gHeadsTaken = 0; gPmRunning = true; gFlipOnPin = false; pins = unpins = 0; };

    // 1. Last user, ownership held: release once, free once, clear both handles.
    { reset(); gDevUsers = 1; gDev = &devA; gHeadsTaken = 0x3u;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true; fb.fOwnsHead = true; fb.fHead = 1;
      fb.dropKapiDevice();
      req(releases == 1 && frees == 1, "last user releases and frees exactly once");
      req(gDev == nullptr && fb.fDev == nullptr && fb.fGrabbedOwnership == false, "last user clears the shared handle");
      req(gDevUsers == 0 && gHeadsTaken == 0x1u, "last user drops its count and its head bit"); }

    // 2. Two users: the first drop must not free.
    { reset(); gDevUsers = 2; gDev = &devA;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true;
      fb.dropKapiDevice();
      req(releases == 1 && frees == 0, "first of two users does not free the device");
      req(gDev == &devA && gDevUsers == 1 && fb.fDev == nullptr, "device stays for the remaining user"); }

    // 3. Second drop frees it.
    { reset(); gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true;
      fb.dropKapiDevice();
      req(frees == 1 && gDev == nullptr && gDevUsers == 0, "last drop frees the shared device"); }

    // 4. Ownership never grabbed: free only.
    { reset(); gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = false;
      fb.dropKapiDevice();
      req(releases == 0 && frees == 1, "no ownership grab means no release"); }

    // 5. Failed before binding a device: only the head bit comes back.
    { reset(); gHeadsTaken = 0x4u;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = nullptr; fb.fOwnsHead = true; fb.fHead = 2;
      fb.dropKapiDevice();
      req(releases == 0 && frees == 0, "no device means no teardown");
      req(gHeadsTaken == 0x0u && gDevUsers == 0, "head bit returned without touching the count"); }

    // 6. A different shared device is left untouched.
    { reset(); gDevUsers = 1; gDev = &devB;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true;
      fb.dropKapiDevice();
      req(frees == 1 && fb.fDev == nullptr, "the bound device is still freed");
      req(gDev == &devB, "a different shared device is left untouched"); }

    // 7. Dropping twice is a no-op the second time.
    { reset(); gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true;
      fb.dropKapiDevice(); fb.dropKapiDevice();
      req(releases == 1 && frees == 1 && gDevUsers == 0, "a second drop does nothing"); }

    // 8. NVKMS suspended, sole user: keep the device, give up the slot, owe the grab.
    { reset(); gPmRunning = false; gDevUsers = 1; gDev = &devA; gHeadsTaken = 0x2u;
      NVRMNVDAFramebuffer fb; fb.fKms = &table; fb.fDev = &devA; fb.fGrabbedOwnership = true; fb.fOwnsHead = true; fb.fHead = 1;
      fb.dropKapiDevice();
      req(releases == 0 && frees == 0, "suspended NVKMS means no teardown at all");
      req(gDev == &devA && gDevUsers == 0, "the slot is given up while the device stays reachable");
      req(fb.fDev == nullptr && fb.fGrabbedOwnership == false, "this framebuffer holds nothing more");
      req(gDevOrphaned == true && gOrphanGrabs == 1, "orphan and one grab debt are recorded");
      req(gHeadsTaken == 0x0u, "the head bit is still returned"); }

    // 9. Orphan with no live user: finished once NVKMS is callable again.
    { reset(); gPmRunning = true; gDev = &devA; gDevUsers = 0; gDevOrphaned = true; gOrphanGrabs = 1;
      NVRMNVDAFramebuffer fb; fb.fKms = &table;
      fb.finishOrphanedDevice();
      req(releases == 1 && frees == 1, "the orphan returns its grab and the device is freed");
      req(gDev == nullptr && gDevOrphaned == false && gOrphanGrabs == 0, "orphan state fully cleared"); }

    // 10. Still suspended: keep the orphan for the next attempt.
    { reset(); gPmRunning = false; gDev = &devA; gDevUsers = 1; gDevOrphaned = true;
      NVRMNVDAFramebuffer fb; fb.fKms = &table;
      fb.finishOrphanedDevice();
      req(releases == 0 && frees == 0 && gDev == &devA && gDevOrphaned == true, "orphan survives a suspended GPU"); }

    // 11. Nothing orphaned: no-op.
    { reset(); gDev = &devA; gDevUsers = 1;
      NVRMNVDAFramebuffer fb; fb.fKms = &table;
      fb.finishOrphanedDevice();
      req(releases == 0 && frees == 0 && gDev == &devA && gDevUsers == 1, "no orphan means nothing happens"); }

    // 12. Orphan flag without a device: no-op, flag stays for inspection.
    { reset(); gDev = nullptr; gDevOrphaned = true;
      NVRMNVDAFramebuffer fb; fb.fKms = &table;
      fb.finishOrphanedDevice();
      req(releases == 0 && frees == 0 && gDev == nullptr, "a flag without a device does nothing"); }

    // 13. Two users, one stops while suspended: the orphan must not free the device the other drives.
    { reset(); gPmRunning = false; gDevUsers = 2; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      a.dropKapiDevice();
      req(frees == 0 && releases == 0, "suspended stop frees nothing");
      req(gDevUsers == 1, "the stopping framebuffer gives up its slot");
      req(gDevOrphaned == true && gOrphanGrabs == 1, "orphan and one grab debt are recorded");
      gPmRunning = true;
      NVRMNVDAFramebuffer c; c.fKms = &table;
      c.finishOrphanedDevice();
      req(frees == 0, "orphan settlement must not free a device another framebuffer still holds");
      req(releases == 1, "the dead framebuffer's grab is returned exactly once");
      req(gDev == &devA && gDevUsers == 1, "the surviving user keeps device and count");
      req(gDevOrphaned == false && gOrphanGrabs == 0, "orphan state is cleared"); }

    // 14. Sole user stops while suspended: the next start settles and frees it.
    { reset(); gPmRunning = false; gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      gDevCreator = &a; a.retain();
      a.dropKapiDevice();
      req(gDevUsers == 0 && frees == 0 && gDev == &devA, "sole user leaves the device for later");
      gPmRunning = true;
      NVRMNVDAFramebuffer c; c.fKms = &table;
      c.finishOrphanedDevice();
      req(frees == 1 && releases == 1, "settlement frees once and returns the grab once");
      req(gDev == nullptr, "settlement clears the shared handle");
      req(creatorReleases == 1, "the creator retain is dropped exactly once");
      req(a.refs == 1, "creator object released back to its base reference"); }


    // 16. Two framebuffers stop while NVKMS is unavailable: the orphan owes one grab per stop.
    { reset(); gPmRunning = false; gDevUsers = 2; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      NVRMNVDAFramebuffer b; b.fKms = &table; b.fDev = &devA; b.fGrabbedOwnership = true;
      a.dropKapiDevice();
      b.dropKapiDevice();
      req(gOrphanGrabs == 2, "each stop records its own grab debt");
      req(gDevUsers == 0 && gDev == &devA, "the device is kept with no live user");
      gPmRunning = true;
      NVRMNVDAFramebuffer c; c.fKms = &table;
      c.finishOrphanedDevice();
      req(releases == 2, "both debts are returned, not one");
      req(frees == 1, "the device is freed once");
      req(gOrphanGrabs == 0, "the debt count reaches zero"); }


    // 17. A resume flips the GPU to LOST right after the pin: the destructive pair must not run.
    { reset(); gDevUsers = 1; gDev = &devA; gFlipOnPin = true;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      a.dropKapiDevice();
      req(releases == 0 && frees == 0, "a state flip inside the pin prevents release and free");
      req(gDev == &devA && gDevOrphaned, "the device is kept and marked orphaned");
      req(gOrphanGrabs == 1, "the grab is recorded as a debt");
      req(gDevUsers == 0 && a.fDev == nullptr, "the instance gives up its slot and handle");
      req(pins == 1 && unpins == 1, "the pin is balanced on this exit"); }

    // 15. Every teardown exit balances the pin, including the "other user remains" path.
    { reset(); gDevUsers = 2; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      a.dropKapiDevice();
      req(pins == 1 && unpins == 1, "the remaining-user path takes and releases exactly one pin"); }
    { reset(); gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      a.dropKapiDevice();
      req(pins == 1 && unpins == 1, "the last-user path takes and releases exactly one pin"); }
    { reset(); gPmRunning = false; gDevUsers = 1; gDev = &devA;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = &devA; a.fGrabbedOwnership = true;
      a.dropKapiDevice();
      req(pins == 0 && unpins == 0, "a refused pin takes nothing to release"); }
    { reset(); gDev = nullptr; gDevUsers = 0;
      NVRMNVDAFramebuffer a; a.fKms = &table; a.fDev = nullptr;
      a.dropKapiDevice();
      req(pins == 0, "no device means no pin at all"); }

    if (failures) { std::printf("RESULT: %d of %d lifetime checks FAILED\n", failures, checks); return 1; }
    std::printf("RESULT: %d/%d lifetime checks passed\n", checks, checks);
    return 0;
}
"""


def main():
    text = SRC.read_text(encoding="utf-8")
    drop = body(text, "void NVRMNVDAFramebuffer::dropKapiDevice()")
    fin = body(text, "void NVRMNVDAFramebuffer::finishOrphanedDevice()")
    drop = drop.replace("void NVRMNVDAFramebuffer::dropKapiDevice()", "void dropKapiDevice()", 1)
    fin = fin.replace("void NVRMNVDAFramebuffer::finishOrphanedDevice()", "void finishOrphanedDevice()", 1)
    program = "\n".join([SHIM, drop, "", fin, MAIN])
    path = OUT / "device-lifetime-actual.cpp"
    header = provenance(SRC)
    path.write_text(header + program, encoding="utf-8")
    print("source_sha256=" + header.splitlines()[1].split(": ")[1])
    meta = {
        "level": "HOST-TEST: the real dropKapiDevice() and finishOrphanedDevice() bodies",
        "source": {"file": "kexts/NVRMFB/fb/nvrm-fb.cpp",
                   "sha256": hashlib.sha256(SRC.read_bytes()).hexdigest()},
        "fixture": {"file": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()},
        "drop_sha256": hashlib.sha256(drop.encode()).hexdigest(),
        "finish_sha256": hashlib.sha256(fin.encode()).hexdigest(),
    }
    (OUT / "lifetime-fixture.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    print("wrote", path.name, "| scenarios: 12")


if __name__ == "__main__":
    main()
