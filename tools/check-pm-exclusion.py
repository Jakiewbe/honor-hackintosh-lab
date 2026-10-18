#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Structure contract for R23: the pin/suspend exclusion, as written in the real files.

The host test proves the behaviour; this proves the shape the behaviour depends on, so a later edit
cannot quietly reintroduce "suspend anyway" or "acknowledge without suspending".
"""
import hashlib
import json
import sys
from pathlib import Path

W = Path(r"D:\Hactk\gpu-r5-20261017")
OS = W / "src/kexts/NVRM/os-nvkms-xnu.cpp"
NVRM = W / "src/kexts/NVRM/NVRM.cpp"
OUT = W / "evidence/r23"
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

    sus = braces(osf, osf.index("NvBool nvkms_xnu_suspend(NvU32 gpuId, uint32_t waitMs)"))
    pin = braces(osf, osf.index("NvBool nvkms_xnu_pm_pin(void)"))
    res = braces(osf, osf.index("void nvkms_xnu_resume(NvU32 gpuId, NvBool gpuOk)"))

    check("suspend reports a result instead of returning void", "NvBool nvkms_xnu_suspend(NvU32 gpuId, uint32_t waitMs)" in osf)
    check("the old 'suspend anyway' log is gone", "suspend proceeded with" not in osf)
    check("the wait watches the pin count", "gKmsPmPins > 0" in sus)
    check("the wait is bounded", "clock_interval_to_deadline" in sus)
    check("a pending request takes a sequence number", "++gKmsSuspendSeq" in sus)
    check("abandon returns before any NVKMS call",
          sus.index("return NV_FALSE;") < sus.index("nvKmsSuspend(gpuId)"))
    check("abandon reopens pin admission",
          "if (stillMine) { gKmsSuspendPending = false; gKmsSuspendSeq++; }" in sus
          and sus.index("if (stillMine)") < sus.index("nvKmsSuspend(gpuId)"))
    check("NVKMS is only told after the pins drained",
          sus.index("nvKmsKapiSuspendResume(NV_TRUE)") > sus.index("gKmsPmPins > 0"))
    check("exactly one nvKmsSuspend call site", sus.count("nvKmsSuspend(gpuId)") == 1)
    check("the commit re-checks the sequence (a resume can overtake)",
          sus.rfind("gKmsSuspendSeq == seq") > sus.index("nvKmsKapiSuspendResume(NV_TRUE)"))
    check("a lost race tells NVKMS to undo", "nvKmsKapiSuspendResume(NV_FALSE)" in sus)

    check("a pin is refused while a suspend is pending", "!gKmsSuspendPending" in pin)
    check("resume clears the pending request", "gKmsSuspendPending = false" in res)
    check("resume bumps the sequence", "gKmsSuspendSeq++" in res)
    check("resume wakes the waiting suspend", "IOLockWakeup(gKmsLock, &gKmsPmPins" in res)

    gs = braces(nv, nv.index("bool NVRM::gpuSuspend()"))
    refusal = gs[gs.index("if (!nvkms_xnu_suspend("):gs.index("const int busy")]
    check("gpuSuspend checks the result", "if (!nvkms_xnu_suspend(" in gs)
    check("refusal returns before the RM gate closes", "return false;" in refusal and "nv_xnu_pm_close" not in refusal)
    check("refusal returns before user channels are stopped", "rm_stop_user_channels" not in refusal)
    check("refusal returns before RM standby", "rm_power_management" not in refusal)
    check("refusal undoes the pm flag", "OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning" in refusal)
    check("refusal re-lights the framebuffers", "notifyFramebuffers(1)" in refusal)
    check("success returns true", gs.rstrip().endswith("return true;\n}"))

    sp = braces(nv, nv.index("IOReturn NVRM::setPowerState(unsigned long ordinal, IOService *device)"))
    check("setPowerState refuses the sleep instead of acknowledging it", "if (!gpuSuspend()) return kIOReturnBusy;" in sp)
    check("setPowerState still acknowledges a real resume", sp.count("return kIOPMAckImplied;") == 1)
    check("no asynchronous ack is used (the call completes synchronously)", "acknowledgeSetPowerState" not in nv)

    rec = {"level": "SOURCE-STRUCTURE (R23 pin/suspend exclusion)",
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
