#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R24 structure contract: begin/commit/abort, with no reliance on a "refusal" return value."""
import hashlib
import json
import sys
from pathlib import Path

W = Path(r"D:\Hactk\gpu-r5-20261017")
OS = W / "src/kexts/NVRM/os-nvkms-xnu.cpp"
NVRM = W / "src/kexts/NVRM/NVRM.cpp"
OUT = W / "evidence/r24"
OUT.mkdir(parents=True, exist_ok=True)


def braces(text, start):
    b = text.index("{", start)
    depth = 0
    for i in range(b, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError("unbalanced")


def main():
    osf = OS.read_text(encoding="utf-8")
    nv = NVRM.read_text(encoding="utf-8")
    checks, fails = [], []

    def check(name, ok, detail=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail})
        if not ok:
            fails.append(name)

    begin = braces(osf, osf.index("NvBool nvkms_xnu_suspend_begin(uint32_t *seqOut)"))
    commit = braces(osf, osf.index("NvBool nvkms_xnu_suspend_commit(NvU32 gpuId, uint32_t seq, uint32_t waitMs)"))
    abort = braces(osf, osf.index("void nvkms_xnu_suspend_abort(uint32_t seq)"))
    pin = braces(osf, osf.index("NvBool nvkms_xnu_pm_pin(void)"))
    res = braces(osf, osf.index("void nvkms_xnu_resume(NvU32 gpuId, NvBool gpuOk)"))

    check("begin refuses unless RUNNING", "gKmsPmState != kKmsPmRunning" in begin)
    check("begin refuses a duplicate", "gKmsSuspendPending" in begin)
    check("begin closes admission", "gKmsSuspendPending = true" in begin)
    check("begin takes a sequence number", "++gKmsSuspendSeq" in begin)
    check("commit verifies the sequence", "gKmsSuspendSeq == seq" in commit)
    check("commit waits on the pin count", "gKmsPmPins > 0" in commit)
    check("commit abandons without touching NVKMS", commit.index("return NV_FALSE") < commit.index("nvKmsSuspend(gpuId)"))
    check("commit suspends exactly once", commit.count("nvKmsSuspend(gpuId)") == 1)
    check("the KAPI notice and the state flip are inside the locked region",
          commit.index("nvKmsKapiSuspendResume(NV_TRUE)") < commit.index("gKmsPmState = kKmsPmSuspended")
          < commit.rindex("IOLockUnlock"))
    check("commit takes the lock once and has no out-of-lock KAPI window",
          commit.count("IOLockLock(gKmsLock)") == 1
          and commit.index("nvKmsKapiSuspendResume(NV_TRUE)") > commit.index("IOLockLock(gKmsLock)"))
    check("abort releases only its own request", "gKmsSuspendSeq == seq" in abort and "gKmsSuspendPending = false" in abort)
    check("a pin is refused while a request is pending", "!gKmsSuspendPending" in pin)
    check("resume cancels a pending request", "gKmsSuspendPending = false" in res and "gKmsSuspendSeq++" in res)

    gs = braces(nv, nv.index("bool NVRM::gpuSuspend()"))
    check("gpuSuspend begins before the framebuffers are told to stop",
          gs.index("nvkms_xnu_suspend_begin") < gs.index("notifyFramebuffers(0)"))
    check("gpuSuspend commits after they were told",
          gs.index("nvkms_xnu_suspend_commit") > gs.index("notifyFramebuffers(0)"))
    fail_block = gs[gs.index("if (!nvkms_xnu_suspend_commit("):gs.index("const int busy")]
    check("a failed commit never closes the RM gate", "nv_xnu_pm_close" not in fail_block)
    check("a failed commit never stops user channels", "rm_stop_user_channels" not in fail_block)
    check("a failed commit never runs RM standby", "rm_power_management" not in fail_block)
    check("a failed commit aborts the request", "nvkms_xnu_suspend_abort(seq)" in fail_block)
    check("a failed commit is recorded as a violation", "nvrm-pm-violation" in fail_block)
    check("a failed commit re-lights the framebuffers", "notifyFramebuffers(1)" in fail_block)

    # The RM gate close cannot refuse a sleep (XNU ack semantics), so a busy gate must be logged and the
    # sleep must continue. Lock that behaviour so it can never silently become a false "gate closed".
    gs_full = braces(nv, nv.index("bool NVRM::gpuSuspend()"))
    close_calls = gs_full.count("nv_xnu_pm_close(")
    check("the RM gate close is attempted exactly once per sleep", close_calls == 1, f"calls={close_calls}")
    busy_block = gs_full[gs_full.index("const int busy = nv_xnu_pm_close"):]
    busy_block = busy_block[:busy_block.index("rm_stop_user_channels")]
    check("a busy RM gate is logged, not silently ignored", "LOG(" in busy_block and "still running" in busy_block)
    check("a busy RM gate does not abort the sleep", "return false" not in busy_block)

    # R24 close-timeout contract: a wait that does not complete is not a completed close. The per-open,
    # its wrapper and its event worker must stay allocated, and nvKmsClose() must not run.
    close_fn = braces(osf, osf.index("static void kms_close_common(struct nvkms_per_open *popen)"))
    wait_at = close_fn.index("kms_pm_wait_locked(false, kKmsPmWaitMs)")
    check("close waits for PM before touching NVKMS",
          wait_at < close_fn.index("nvKmsClose(popen->data)"),
          "wait must precede nvKmsClose")
    deferred = close_fn[wait_at:close_fn.index("return;", wait_at)]
    check("a timed-out close never calls nvKmsClose", "nvKmsClose" not in deferred)
    check("a timed-out close retains the wrapper", "nvkms_free" not in deferred)
    check("a timed-out close refuses new work", "popen->closing = true" in deferred)
    check("a timed-out close is counted", "gKmsCloseDeferred++" in deferred)

    sp = braces(nv, nv.index("IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device)"))
    check("setPowerState does not pretend to refuse the sleep", "kIOReturnBusy" not in sp)
    check("setPowerState records a violation when the suspend failed", "nvrm-pm-violation" in sp)
    check("setPowerState acknowledges exactly once", sp.count("return kIOPMAckImplied;") == 1)

    rec = {"level": "SOURCE-STRUCTURE (R24 begin/commit/abort)",
           "source_sha256": {"os-nvkms-xnu.cpp": hashlib.sha256(OS.read_bytes()).hexdigest(),
                             "NVRM.cpp": hashlib.sha256(NVRM.read_bytes()).hexdigest()},
           "checks": checks, "result": "PASS" if not fails else "FAIL", "failures": fails}
    (OUT / "structure.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
    for c in checks:
        print(("PASS " if c["ok"] else "FAIL ") + c["check"] + (("  [" + c["detail"] + "]") if c["detail"] and not c["ok"] else ""))
    print(f"RESULT: {len(checks) - len(fails)}/{len(checks)} checks; {rec['result']}")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
